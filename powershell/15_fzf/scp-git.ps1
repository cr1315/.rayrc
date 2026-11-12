######################################################################
## scp-git: リモートのリポジトリを lf で選び、git bundle にして手元に持ってくる
##
##   scp-git [[-HostFilter] <string>] [-StartDir <string>] [-Destination <string>]
##           [-RayrcDir <string>] [-KeepRemote]
##
## 流れ（接続は 3 回。Windows の OpenSSH は ControlMaster が使えない）
##   1. ssh.exe -t <host> '<rayrc>/bash/10_viewer/20_git/rayrc-git-bundle -o /tmp/scp-git-<ID> -s <開始フォルダ>'
##      リモートで lf が開き、選んだリポジトリのバンドルが /tmp/scp-git-<ID> にできる
##   2. scp.exe <host>:/tmp/scp-git-<ID>/*.bundle <保存先>
##   3. ssh.exe <host> 'rm -rf /tmp/scp-git-<ID>'（失敗・中止でも必ず実行）
##   親フォルダを他のユーザーと共有しないよう、/tmp の直下に 1 回ごとのフォルダを作る
##
## 注意
##   - ssh は関数で上書きしているので、中では必ず ssh.exe / scp.exe を使う
##   - lf の画面が壊れるので、1 の出力は変数で受けない
##   - PowerShell 5.1 は外部コマンドへの引数の中の " を消すので、リモートに渡す文字列に
##     " を入れない（-StartDir / -RayrcDir の検査でそれを保証する）
######################################################################

function scp-git {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$HostFilter,
        [string]$StartDir = '~',
        [string]$Destination = '.',
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
    if (-not (Test-Path -LiteralPath $Destination -PathType Container)) {
        Write-Error "保存先のフォルダがありません：$Destination"
        return
    }
    $destFull = (Resolve-Path -LiteralPath $Destination).ProviderPath

    ## 1. ホストを決める
    $sshHost = Get-RayrcSshHost $HostFilter
    if (-not $sshHost) {
        return
    }

    ## 2. ID とリモートの出力先
    $id = '{0}-{1:D4}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'), (Get-Random -Minimum 0 -Maximum 10000)
    $remoteDir = "/tmp/scp-git-$id"
    $remoteScript = "$RayrcDir/bash/10_viewer/20_git/rayrc-git-bundle"
    ## ~ はリモートのシェルに展開させる。変数で渡すので PowerShell 側では展開されない
    $remoteCmd = "$remoteScript -o $remoteDir -s $StartDir"

    $fetched = @()
    try {
        ## 3. 対話の接続（lf → バンドル作成）。出力は受けない
        Write-Host "& ssh.exe -t $sshHost '$remoteCmd'"
        & ssh.exe -t $sshHost $remoteCmd
        $code = $LASTEXITCODE

        switch ($code) {
            0 { }
            2 {
                Write-Host '何も選ばれなかったので、何もしません'
                return
            }
            3 {
                Write-Host '対象なし：選んだものの中に、バンドルにできるリポジトリがありませんでした'
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

        ## 4. 取得（ワイルドカードはリモートで展開される）
        ## 取る前の状態を控え、新しくできたものと更新日時が変わったものを今回の分とする
        $before = @{}
        foreach ($f in (Get-ChildItem -LiteralPath $destFull -Filter '*.bundle' -File)) {
            $before[$f.Name] = $f.LastWriteTimeUtc
        }
        Write-Host "& scp.exe '${sshHost}:$remoteDir/*.bundle' '$Destination'"
        & scp.exe "${sshHost}:$remoteDir/*.bundle" $Destination
        if ($LASTEXITCODE -ne 0) {
            Write-Error "scp.exe に失敗しました（終了コード $LASTEXITCODE）"
        }

        ## scp は（-p なしなら）上書きでも更新日時を今にするので、それで見分けられる
        $fetched = @(Get-ChildItem -LiteralPath $destFull -Filter '*.bundle' -File |
                Where-Object { -not $before.ContainsKey($_.Name) -or $before[$_.Name] -ne $_.LastWriteTimeUtc } |
                Sort-Object Name)
    }
    finally {
        ## 5. 後片付け（中止・失敗のときも必ず）
        if ($KeepRemote) {
            Write-Host "リモートのバンドルは残しています：${sshHost}:$remoteDir"
        }
        else {
            & ssh.exe $sshHost "rm -rf $remoteDir"
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "リモートの後片付けに失敗しました：${sshHost}:$remoteDir"
            }
        }
    }

    ## 6. 取得したファイルの一覧
    if ($fetched.Count -eq 0) {
        return
    }
    $hasGit = [bool](Get-Command -CommandType Application git -ErrorAction SilentlyContinue)
    Write-Host ''
    Write-Host "== 取得したバンドル（$($fetched.Count) 件）：$destFull"
    foreach ($f in $fetched) {
        $size = if ($f.Length -ge 1MB) { '{0:N1}MB' -f ($f.Length / 1MB) }
        elseif ($f.Length -ge 1KB) { '{0:N1}KB' -f ($f.Length / 1KB) }
        else { "$($f.Length)B" }

        $refs = ''
        if ($hasGit) {
            ## verify は手元のリポジトリが要るので、list-heads で読めることだけ確かめる
            $heads = @(& git bundle list-heads $f.FullName 2>$null)
            if ($LASTEXITCODE -eq 0) {
                $refs = "refs $($heads.Count)"
            }
            else {
                $refs = '読めません（git bundle list-heads に失敗）'
            }
        }
        Write-Host ('  {0}  {1}  {2}' -f $f.Name, $size, $refs)
    }
}
