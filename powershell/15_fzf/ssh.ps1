######################################################################
## ssh: ~/.ssh/*config のホストから接続先を選んで ssh.exe を呼ぶ
##   ssh              全ホストを fzf で選ぶ
##   ssh <filter>     絞り込み（完全一致・1 件ならそのまま、複数なら fzf）
##   ssh -V / ssh a b 2 つ以上の引数、または - で始まる 1 つの引数はそのまま ssh.exe へ
######################################################################

## ホストを 1 つ決めて返す。fzf で Esc のとき・候補が無いときは $null
##   $Filter が空：全件を fzf で選ばせる
##   $Filter と完全一致するものがあれば、それで確定
##   部分一致（正規表現）が 1 件ならそれ、複数なら fzf（--query $Filter）
##   0 件なら $Filter をそのままホスト名として返す
function Get-RayrcSshHost {
    param([string]$Filter)

    ## 1. ~/.ssh 配下の *config から、接続先として使える Host 名を書かれた順に集める
    ##   - Host a b c は空白で分割する
    ##   - *・? を含むもの、! で始まるもの（パターン）は除く
    ##   - 大文字小文字、行頭の空白、Host=name の形にも対応する
    $hosts = [System.Collections.Generic.List[string]]::new()
    $seen = @{}
    $sshDir = Join-Path $env:USERPROFILE '.ssh'
    if (Test-Path -LiteralPath $sshDir -PathType Container) {
        foreach ($file in (Get-ChildItem -LiteralPath $sshDir -Filter '*config' -Recurse -File -ErrorAction SilentlyContinue)) {
            foreach ($line in [System.IO.File]::ReadAllLines($file.FullName)) {
                ## -match は大文字小文字を区別しない。HostName は Host の後が空白でも = でもないので外れる
                if ($line -notmatch '^\s*Host(?:\s*=\s*|\s+)(.+)$') {
                    continue
                }
                foreach ($name in ($Matches[1].Trim() -split '\s+')) {
                    if ($name -eq '' -or $name -match '[*?]' -or $name.StartsWith('!')) {
                        continue
                    }
                    if (-not $seen.ContainsKey($name)) {
                        $seen[$name] = $true
                        $hosts.Add($name)
                    }
                }
            }
        }
    }

    ## 2. 絞り込み

    if ([string]::IsNullOrEmpty($Filter)) {
        $candidates = @($hosts)
    }
    else {
        $exact = @($hosts | Where-Object { $_ -eq $Filter })
        if ($exact.Count -gt 0) {
            return $exact[0]
        }
        $candidates = @($hosts | Where-Object { $_ -match $Filter })
        if ($candidates.Count -eq 1) {
            return $candidates[0]
        }
        if ($candidates.Count -eq 0) {
            return $Filter
        }
    }

    if ($candidates.Count -eq 0) {
        Write-Warning "~/.ssh の *config に接続先の Host がありません"
        return $null
    }

    ## 3. fzf で選ぶ（Esc なら $null）
    ## PowerShell 5.1 は外部コマンドへの空文字の引数を落とすので、--query は値があるときだけ付ける
    $fzfArgs = @()
    if (-not [string]::IsNullOrEmpty($Filter)) {
        $fzfArgs += @('--query', $Filter)
    }
    $selected = $candidates | fzf-real @fzfArgs
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($selected)) {
        return $null
    }
    return "$selected".Trim()
}

function ssh {
    $sshBin = (Get-Command -CommandType Application ssh | Select-Object -First 1).Path

    ## shortcut: そのまま ssh.exe に渡す
    if ($args.Count -ge 2 -or ($args.Count -eq 1 -and "$($args[0])" -match '^-')) {
        & $sshBin @args
        return
    }

    $sshHost = Get-RayrcSshHost -Filter "$($args[0])"
    if (-not $sshHost) {
        return
    }

    Write-Host "& '$sshBin' $sshHost"
    & $sshBin $sshHost
}
