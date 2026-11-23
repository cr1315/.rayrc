######################################################################
## lfscp: リモートの lf の中で選んで作ったもの（かご = セッションの out/）を手元に運ぶ
##
##   lfscp [[-HostFilter] <string>] [[-StartDir] <string>] [[-To] <string>]
##         [-RayrcDir <string>] [-KeepRemote]
##   別名 scp-lf（PowerShell の動詞-名詞の流儀）
##
##   lfscp ec2-dev                        # リモートの ~ から開始、カレントへ保存
##   lfscp ec2-dev ~/work C:\tmp\in       # 開始フォルダと保存先を指定
##
## 流れ（接続は 3 回。Windows の OpenSSH は ControlMaster が使えない）
##   1. ssh.exe -t <host> '<rayrc>/src/10_viewer/48_lfscp/lfscp -o /tmp/lfscp-<user>-<ID> -s <開始フォルダ>'
##      リモートで lf が開き、t 系のキーで作ったものがセッションの out/ に入る
##   2. scp.exe -r <host>:<セッション>/out <保存先>/.lfscp-<ID>（失敗したら計 3 回まで）→ 保存先へ移す
##   3. ssh.exe <host> 'rm -rf -- <セッション>'（取得に失敗したときだけ残す）
##   形式の知識はリモートの lfscp に閉じる。ここはパスの決定・運搬・片付けだけ
##
## 注意
##   - ssh は関数で上書きしているので、中では必ず ssh.exe / scp.exe を使う
##   - lf の画面が壊れるので、1 の出力は変数で受けない
##   - PowerShell 5.1 は外部コマンドへの引数の中の " を消すので、リモートに渡す文字列に
##     " を入れない（-StartDir / -RayrcDir の検査とセッション名の置き換えでそれを保証する）
##   - リモートはリンク（libs/bin/lfscp）ではなく src の実体をフルパスで呼ぶ。
##     非対話の ssh では PATH が効かず、install 前の git pull 直後でも動かすため
######################################################################

## out/ をまだ無い名前のステージングへ運ぶ。成功したときだけ $Staging が残る
##   コピー先が存在しないと scp -r はそのフォルダを作って out/ の中身を入れる（ワイルドカードを使わない）
##   rsync などに差し替えるときは、この関数の中だけを変える
##   値を返さないのは、式の中で呼ぶと scp.exe の標準出力が取り込まれ、進み具合が端末に出なくなるため
##   （文として呼べば、scp.exe はそのまま端末に書く）
function Invoke-LfscpFetch {
    param(
        [Parameter(Mandatory = $true)][string]$SshHost,
        [Parameter(Mandatory = $true)][string]$Session,
        [Parameter(Mandatory = $true)][string]$Staging,
        [int]$Attempts = 3,
        [int]$WaitSeconds = 3
    )

    for ($i = 1; $i -le $Attempts; $i++) {
        if (Test-Path -LiteralPath $Staging) {
            Remove-Item -LiteralPath $Staging -Recurse -Force
        }
        Write-Host "& scp.exe -r '${SshHost}:$Session/out' '$Staging'"
        & scp.exe -r "${SshHost}:$Session/out" $Staging
        $code = $LASTEXITCODE
        if ($code -eq 0 -and (Test-Path -LiteralPath $Staging -PathType Container)) {
            return
        }
        Write-Warning "scp.exe に失敗しました（終了コード $code、$i / $Attempts 回目）"
        if ($i -lt $Attempts) {
            Start-Sleep -Seconds $WaitSeconds
        }
    }

    if (Test-Path -LiteralPath $Staging) {
        Remove-Item -LiteralPath $Staging -Recurse -Force
    }
}

function lfscp {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$HostFilter,
        [Parameter(Position = 1)]
        [string]$StartDir = '~',
        [Parameter(Position = 2)]
        [Alias('Destination')]
        [string]$To = '.',
        [string]$RayrcDir = '~/.rayrc',
        [switch]$KeepRemote
    )

    ## リモートに渡す文字列に、引用符や空白を入れない
    $safePattern = '^[A-Za-z0-9~/._-]+$'
    foreach ($item in @(@('StartDir', $StartDir), @('RayrcDir', $RayrcDir))) {
        if ($item[1] -notmatch $safePattern) {
            Write-Error "-$($item[0]) に使えるのは英数字と ~ / . - _ だけです：$($item[1])"
            return
        }
    }
    if (-not (Test-Path -LiteralPath $To -PathType Container)) {
        Write-Error "保存先のフォルダがありません：$To"
        return
    }
    $destFull = (Resolve-Path -LiteralPath $To).ProviderPath

    ## 1. ホストを決める（10_fzf の Get-RayrcSshHost。無ければ値をそのままホスト名に使う）
    if (Get-Command Get-RayrcSshHost -ErrorAction SilentlyContinue) {
        $sshHost = Get-RayrcSshHost $HostFilter
    }
    else {
        $sshHost = $HostFilter
    }
    if (-not $sshHost) {
        if (-not $HostFilter) {
            Write-Error '接続先を指定してください（-HostFilter）'
        }
        return
    }

    ## 2. セッションのパス（ここで丸ごと決める。scp と rm も同じ文字列を使う）
    ##   <user> はただのラベル。リモートの検査を通すため [A-Za-z0-9._-] 以外は _ にする
    $user = $null
    foreach ($line in @(& ssh.exe -G $sshHost 2>$null)) {
        if ("$line" -match '^user\s+(\S+)') {
            $user = $Matches[1]
            break
        }
    }
    if (-not $user) {
        $user = $env:USERNAME
    }
    $user = $user -replace '[^A-Za-z0-9._-]', '_'
    $id = '{0}-{1:D4}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'), (Get-Random -Minimum 0 -Maximum 10000)
    $session = "/tmp/lfscp-$user-$id"
    $remoteScript = "$RayrcDir/src/10_viewer/48_lfscp/lfscp"
    ## ~ はリモートのシェルに展開させる
    $remoteCmd = "$remoteScript -o $session -s $StartDir"
    $staging = Join-Path $destFull ".lfscp-$id"

    $keep = [bool]$KeepRemote
    $fetched = @()
    try {
        ## 3. 対話の接続（lf の中で作る）。出力は受けない
        Write-Host "& ssh.exe -t $sshHost '$remoteCmd'"
        & ssh.exe -t $sshHost $remoteCmd
        $code = $LASTEXITCODE

        switch ($code) {
            0 { }
            2 {
                Write-Host 'かごが空なので、何もしません'
                return
            }
            { $_ -eq 126 -or $_ -eq 127 } {
                Write-Error "リモートに $remoteScript が無いか、実行できません（終了コード $code）。リモートの rayrc を最新にしてください（git pull）"
                return
            }
            255 {
                Write-Error "$sshHost に接続できませんでした（ssh.exe の終了コード 255）"
                return
            }
            default {
                Write-Error "リモートでエラーが起きました（終了コード $code）"
                return
            }
        }

        ## 4. 取得。失敗し続けたらリモートを残し、取り直しのコマンドを出す
        Invoke-LfscpFetch -SshHost $sshHost -Session $session -Staging $staging
        if (-not (Test-Path -LiteralPath $staging -PathType Container)) {
            $keep = $true
            Write-Error "取得に失敗しました。リモートのセッションを残しています（24 時間後に自動で消えます）"
            Write-Host '取り直すとき（コピー先はまだ無いフォルダにする）：'
            Write-Host "  & scp.exe -r '${sshHost}:$session/out' '$staging'"
            Write-Host "取り終えたら：& ssh.exe $sshHost 'rm -rf -- $session'"
            return
        }

        ## 5. ステージングから保存先へ 1 件ずつ移す（同名は上書きして印を付ける）
        foreach ($item in @(Get-ChildItem -LiteralPath $staging -Force | Sort-Object Name)) {
            $target = Join-Path $destFull $item.Name
            $overwrote = Test-Path -LiteralPath $target
            Move-Item -LiteralPath $item.FullName -Destination $target -Force
            $fetched += [pscustomobject]@{ Item = (Get-Item -LiteralPath $target -Force); Overwrote = $overwrote }
        }
        Remove-Item -LiteralPath $staging -Recurse -Force
    }
    finally {
        ## 6. 後片付け（中止・失敗・Ctrl-C でも。取得に失敗したときと -KeepRemote のときは残す）
        if ($keep) {
            if ($KeepRemote) {
                Write-Host "リモートのセッションは残しています（24 時間後に自動で消えます）：${sshHost}:$session"
            }
        }
        else {
            & ssh.exe $sshHost "rm -rf -- $session"
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "リモートの後片付けに失敗しました：${sshHost}:$session"
            }
        }
    }

    ## 7. 一覧（.bundle だけ refs の数を出す。ほかはリモートで検証済みなので手元では見直さない）
    if ($fetched.Count -eq 0) {
        return
    }
    $hasGit = [bool](Get-Command -CommandType Application git -ErrorAction SilentlyContinue)
    Write-Host ''
    Write-Host "== 取得したもの（$($fetched.Count) 件）：$destFull"
    foreach ($entry in $fetched) {
        $f = $entry.Item
        $len = if ($f -is [System.IO.FileInfo]) { $f.Length } else { 0 }
        $size = if ($len -ge 1MB) { '{0:N1}MB' -f ($len / 1MB) }
        elseif ($len -ge 1KB) { '{0:N1}KB' -f ($len / 1KB) }
        else { "${len}B" }

        $notes = @()
        if ($entry.Overwrote) {
            $notes += '上書き'
        }
        if ($hasGit -and $f.Name -like '*.bundle') {
            ## verify は手元のリポジトリが要るので、list-heads で読めることだけ確かめる
            $heads = @(& git bundle list-heads $f.FullName 2>$null)
            if ($LASTEXITCODE -eq 0) {
                $notes += "refs $($heads.Count)"
            }
            else {
                $notes += '読めません（git bundle list-heads に失敗）'
            }
        }
        Write-Host ('  {0}  {1}  {2}' -f $f.Name, $size, ($notes -join '、'))
    }
}

Set-Alias scp-lf lfscp
