<#
  Confluence Cloud のページを zip で取り込む・書き出す関数（PowerShell のプロファイルから読み込む）

    Import-ConfluencePage -Input .\330137615_promote.zip      # zip の中身でページを更新する
    Export-ConfluencePage 330137615                          # ページを zip に書き出す（URL でもよい）

  環境変数（なければ、そのつど入力を求める）
    RAYRC_JIRA_BASE_URL  ページ ID だけを渡したときのサイトの URL（例：https://xxxxxxxxx.atlassian.net）
    RAYRC_JIRA_EMAIL     ホスト名ごとの Atlassian のメールアドレス
    RAYRC_JIRA_TOKEN     ホスト名ごとの API トークン（https://id.atlassian.com/manage-profile/security/api-tokens）

    RAYRC_JIRA_EMAIL と RAYRC_JIRA_TOKEN は「ホスト名=値」をカンマか空白（改行でもよい）で区切って並べる。
    値は最初の = より後ろ全部（トークンが = を含んでもよい）。ホスト名の大文字・小文字は区別しない。
      RAYRC_JIRA_EMAIL = 'xxx.atlassian.net=me@example.com,yyy.atlassian.net=me@example.org'
      RAYRC_JIRA_TOKEN = 'xxx.atlassian.net=ATATT...,yyy.atlassian.net=ATATT...'
    秘密情報なので、このリポジトリの外で設定すること。zsh 版（main.zsh）と同じ決まり。

  zip の決まり
    - 中に page.xhtml（ストレージ形式の本文）が 1 つあること。図などはその隣に置く
    - 名前が「<ページ ID>_<名前>.zip」なら、ページ ID はそこから読む（-Url を省略できる）

  Windows PowerShell 5.1 と PowerShell 7 の両方で動くように書いている。HTTP は curl.exe を使う。
#>
New-Module -Name Confluence -ScriptBlock {

    $Utf8 = New-Object System.Text.UTF8Encoding($false)   # BOM なし

    # ---- 共通 ----

    function Get-CfSite([string]$FromUrl) {
        $site = if ($FromUrl) { $FromUrl } elseif ($env:RAYRC_JIRA_BASE_URL) { $env:RAYRC_JIRA_BASE_URL } else { Read-Host "Atlassian のサイトの URL（例：https://xxx.atlassian.net）" }
        if ($site.Trim() -notmatch '^(https://[^/]+)') { throw "サイトの URL の形が違います：$site" }
        return $Matches[1].ToLower()
    }

    # URL またはページ ID から、サイトとページ ID を取り出す
    function Resolve-CfPage([string]$Ref) {
        $Ref = $Ref.Trim().Trim('"')
        if ($Ref -match '^\d+$') { return @{ Site = (Get-CfSite); PageId = $Ref } }
        if ($Ref -match '^(https://[^/]+)/wiki/.*?/pages/(?:[a-z0-9-]+/)*?(\d+)') { return @{ Site = $Matches[1].ToLower(); PageId = $Matches[2] } }
        if ($Ref -match '^(https://[^/]+)/wiki/.*[?&]pageId=(\d+)') { return @{ Site = $Matches[1].ToLower(); PageId = $Matches[2] } }
        throw "ページの URL か ID を指定してください（/pages/<数字>/ か pageId=<数字> を含む URL。短縮 URL /wiki/x/... は不可）：$Ref"
    }

    # 「ホスト名=値」をカンマか空白で区切った環境変数から、ホスト名の値を引く（なければ $null）
    function Get-CfMapValue([string]$Name, [string]$HostName) {
        $raw = [Environment]::GetEnvironmentVariable($Name)
        if (-not $raw) { return $null }
        foreach ($entry in ($raw -split '[,\s]+')) {
            if (-not $entry) { continue }
            # 値は秘密情報なので、表示しない
            if ($entry -notmatch '^([^=]+)=(.+)$') { Write-Warning "$Name に「ホスト名=値」の形でないものがあるので無視します"; continue }
            if ($Matches[1] -eq $HostName) { return $Matches[2] }   # -eq は大文字・小文字を区別しない
        }
        return $null
    }

    function Get-CfAuth([string]$HostName, [string]$Email) {
        if (-not $Email) { $Email = Get-CfMapValue 'RAYRC_JIRA_EMAIL' $HostName }
        if (-not $Email) { $Email = Read-Host "Atlassian のメールアドレス（$HostName）" }
        $token = Get-CfMapValue 'RAYRC_JIRA_TOKEN' $HostName
        if (-not $token) {
            $secure = Read-Host "API トークン（$HostName）" -AsSecureString
            $token = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
        }
        return "${Email}:${token}"
    }

    # curl.exe を呼ぶ。応答はファイル経由で UTF-8 として読む（コンソールの文字コードに左右されない）
    function Invoke-CfCurl([string]$Auth, [string[]]$CurlArgs, [string]$OutFile) {
        $tmp = $null
        if (-not $OutFile) { $tmp = [IO.Path]::GetTempFileName(); $OutFile = $tmp }
        try {
            $code = & curl.exe -sS -L -u $Auth -o $OutFile -w '%{http_code}' @CurlArgs
            if ($LASTEXITCODE -ne 0 -or [int]$code -ge 400) {
                $detail = if (Test-Path -LiteralPath $OutFile) { [IO.File]::ReadAllText($OutFile, $Utf8) } else { '' }
                throw "API の呼び出しに失敗しました（HTTP $code。認証・権限・URL を確認）：$($CurlArgs[-1])`n$detail"
            }
            if ($tmp) { return [IO.File]::ReadAllText($tmp, $Utf8) }
        }
        finally { if ($tmp) { Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue } }
    }

    function Get-CfJson([string]$Auth, [string]$Url) { (Invoke-CfCurl $Auth @($Url)) | ConvertFrom-Json }

    function Get-CfAttachments([string]$Auth, [string]$Api, [string]$PageId) {
        $all = @(); $start = 0
        do {
            $r = Get-CfJson $Auth "$Api/content/$PageId/child/attachment?limit=100&start=$start&expand=metadata"
            $all += $r.results; $start += $r.size
        } while ($r._links.next)
        return $all
    }

    # ---- 取り込み ----

    function Import-ConfluencePage {
        <#
      .SYNOPSIS  zip（page.xhtml と図）の中身で、Confluence のページを更新する
      .DESCRIPTION
        1. 本文が参照している図を添付に反映する。中身が同じ図は上げない（添付のコメントの sha256 で比べる）
        2. この関数が上げた図（コメントが sha256: で始まる）のうち、本文が参照しなくなったものを削除する（-NoPrune で無効）
        3. 本文を page.xhtml で丸ごと置き換える。タイトルは -Title を付けなければ今のまま
        zip は $env:TEMP の下に展開し、終わったら（失敗しても）消す
      .EXAMPLE  Import-ConfluencePage -Input .\330137615_promote.zip
      .EXAMPLE  Import-ConfluencePage .\sonar.zip -Url https://xxx.atlassian.net/wiki/spaces/KEY/pages/123/Title
    #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, Position = 0)][Alias('Input')][string]$InputFile,
            [Alias('PageId')][string]$Url,            # URL かページ ID。省略すると zip の名前の先頭の数字を使う
            [string]$Title,
            [string]$Message = "Import-ConfluencePage で更新",
            [string]$Email,
            [switch]$NoPrune
        )
        $ErrorActionPreference = 'Stop'
        $zip = (Resolve-Path -LiteralPath $InputFile).Path
        if ([IO.Path]::GetExtension($zip) -ne '.zip') { throw "zip を指定してください：$zip" }

        if (-not $Url) {
            if ([IO.Path]::GetFileName($zip) -match '^(\d+)_') { $Url = $Matches[1] }
            else { $Url = Read-Host "反映先のページの URL か ID（zip の名前を <ページ ID>_<名前>.zip にすれば省略できる）" }
        }
        $page = Resolve-CfPage $Url
        $api = "$($page.Site)/wiki/rest/api"; $id = $page.PageId
        $auth = Get-CfAuth ($page.Site -replace '^https://', '') $Email

        $work = Join-Path $env:TEMP ("confluence-import_" + [guid]::NewGuid().ToString('N').Substring(0, 8))
        try {
            Expand-Archive -LiteralPath $zip -DestinationPath $work
            $found = @(Get-ChildItem -LiteralPath $work -Recurse -Filter 'page.xhtml' -File)
            if ($found.Count -ne 1) { throw "zip の中に page.xhtml がちょうど 1 つ必要です（見つかった数：$($found.Count)）" }
            $dir = $found[0].DirectoryName

            $info = Get-CfJson $auth "$api/content/${id}?expand=version"
            if (-not $Title) { $Title = $info.title }
            Write-Host "ページ：$($info.title)（版 $($info.version.number)、ID $id）"

            # 図
            $body = [IO.File]::ReadAllText($found[0].FullName, $Utf8)
            $wanted = @([regex]::Matches($body, 'ri:attachment ri:filename="([^"]+)"') | ForEach-Object { [Net.WebUtility]::HtmlDecode($_.Groups[1].Value) } | Select-Object -Unique)
            $missing = @($wanted | Where-Object { -not (Test-Path -LiteralPath (Join-Path $dir $_)) })
            if ($missing) { throw "本文が参照している図が zip にありません：$($missing -join ', ')" }

            $remote = @{}
            foreach ($a in (Get-CfAttachments $auth $api $id)) { $remote[$a.title] = $a }
            foreach ($name in $wanted) {
                $path = Join-Path $dir $name
                $comment = "sha256:" + (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLower()
                if ($remote.ContainsKey($name) -and $remote[$name].metadata.comment -eq $comment) { Write-Host "図：$name（変更なし）"; continue }
                Write-Host "図：$name（アップロード）"
                Invoke-CfCurl $auth @("-X", "PUT", "-H", "X-Atlassian-Token: no-check",
                    "-F", "file=@$path", "-F", "comment=$comment", "-F", "minorEdit=true",
                    "$api/content/$id/child/attachment") | Out-Null
            }
            if (-not $NoPrune) {
                foreach ($name in @($remote.Keys)) {
                    $c = $remote[$name].metadata.comment
                    if (($c -like 'sha256:*') -and ($wanted -notcontains $name)) {
                        Write-Host "図：$name（本文が参照しなくなったので削除）"
                        Invoke-CfCurl $auth @("-X", "DELETE", "$api/content/$($remote[$name].id)") | Out-Null
                    }
                }
            }

            # 本文
            $payload = @{
                id = $id; type = 'page'; title = $Title
                version = @{ number = $info.version.number + 1; message = $Message }
                body = @{ storage = @{ value = $body; representation = 'storage' } }
            } | ConvertTo-Json -Depth 6
            $json = Join-Path $work '.payload.json'
            [IO.File]::WriteAllText($json, $payload, $Utf8)
            Invoke-CfCurl $auth @("-X", "PUT", "-H", "Content-Type: application/json; charset=utf-8",
                "--data-binary", "@$json", "$api/content/$id") | Out-Null
            Write-Host "完了（版 $($info.version.number + 1)）：$($page.Site)/wiki/pages/viewpage.action?pageId=$id"
        }
        finally {
            Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # ---- 書き出し ----

    function Export-ConfluencePage {
        <#
      .SYNOPSIS  Confluence のページを zip に書き出す（page.xhtml・page.json・添付ファイル）
      .DESCRIPTION
        zip の名前は「<ページ ID>_<タイトル>.zip」。そのまま Import-ConfluencePage に渡せる
        - page.xhtml：本文（ストレージ形式）
        - page.json ：ID、タイトル、版、スペース、書き出した日時、添付の一覧
        - 添付ファイル：ページのすべての添付（今の版）
      .EXAMPLE  Export-ConfluencePage 330137615
      .EXAMPLE  Export-ConfluencePage https://xxx.atlassian.net/wiki/spaces/KEY/pages/330137615/promote -OutputDir ~\Downloads
    #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, Position = 0)][Alias('Url', 'PageId')][string]$Page,
            [string]$OutputDir = (Get-Location).Path,
            [string]$Email,
            [switch]$Force
        )
        $ErrorActionPreference = 'Stop'
        $p = Resolve-CfPage $Page
        $api = "$($p.Site)/wiki/rest/api"; $id = $p.PageId
        $auth = Get-CfAuth ($p.Site -replace '^https://', '') $Email

        $info = Get-CfJson $auth "$api/content/${id}?expand=body.storage,version,space"
        $safe = ($info.title -replace '[\\/:*?"<>|\s]+', '_').Trim('_')
        if ($safe.Length -gt 60) { $safe = $safe.Substring(0, 60) }
        $out = Join-Path (Resolve-Path -LiteralPath $OutputDir).Path "${id}_$safe.zip"
        if ((Test-Path -LiteralPath $out) -and -not $Force) { throw "すでにあります（上書きするときは -Force）：$out" }

        $work = Join-Path $env:TEMP ("confluence-export_" + [guid]::NewGuid().ToString('N').Substring(0, 8))
        New-Item -ItemType Directory -Path $work | Out-Null
        try {
            [IO.File]::WriteAllText((Join-Path $work 'page.xhtml'), $info.body.storage.value, $Utf8)
            $atts = @(Get-CfAttachments $auth $api $id)
            $n = 0
            foreach ($a in $atts) {
                Write-Host "添付：$($a.title)"
                $tmp = Join-Path $work ('.dl_{0}' -f ++$n)          # curl.exe に日本語のパスを渡さない
                Invoke-CfCurl $auth @("$($p.Site)/wiki$($a._links.download)") $tmp | Out-Null
                Move-Item -LiteralPath $tmp -Destination (Join-Path $work $a.title)
            }
            $meta = [ordered]@{
                id = $id; title = $info.title; version = $info.version.number; space = $info.space.key
                site = $p.Site; exportedAt = (Get-Date).ToString('s')
                attachments = @($atts | ForEach-Object { [ordered]@{ title = $_.title; mediaType = $_.extensions.mediaType; comment = $_.metadata.comment } })
            }
            [IO.File]::WriteAllText((Join-Path $work 'page.json'), ($meta | ConvertTo-Json -Depth 4), $Utf8)

            if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out }
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [IO.Compression.ZipFile]::CreateFromDirectory($work, $out)
            Write-Host "完了（版 $($info.version.number)、添付 $($atts.Count) 件）：$out"
        }
        finally {
            Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Export-ModuleMember -Function Import-ConfluencePage, Export-ConfluencePage
} | Import-Module -Global
