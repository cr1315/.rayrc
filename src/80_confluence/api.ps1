<#
  ④ 共通：認証、curl、ページ送りのある一覧、URL の読み取り（api.zsh の PowerShell 版）
    Confluence の REST API を呼ぶための道具だけを置く。ページの中身・zip・入れ子は知らない。
    層の分け方は refactoring.md を参照。

  main.ps1 の New-Module の中で dot-source する（関数はモジュールの外に出さない）。
  失敗は throw で知らせる（zsh 版の「メッセージを出して return 8」に当たる）。
#>

$CfUtf8 = New-Object System.Text.UTF8Encoding($false)   # BOM なし

function Assert-CfCommand([string[]]$Names) {
    foreach ($c in $Names) {
        if (-not (Get-Command $c -CommandType Application, Function -ErrorAction SilentlyContinue)) { throw "$c が見つかりません" }
    }
}

# Get-CfSite [<URL>] → https://<ホスト名>
# URL がなければ RAYRC_JIRA_BASE_URL、それもなければ入力を求める
function Get-CfSite([string]$FromUrl) {
    $site = if ($FromUrl) { $FromUrl } else { $env:RAYRC_JIRA_BASE_URL }
    if (-not $site) { $site = Read-Host "Atlassian のサイトの URL（例：https://xxx.atlassian.net）" }
    if ("$site" -notmatch '^\s*(https://[^/\s]+)') { throw "サイトの URL の形が違います：$site" }
    return $Matches[1].ToLowerInvariant()
}

# Resolve-CfPage <URL かページ ID> → @{ Site; PageId }
function Resolve-CfPage([string]$Ref) {
    $Ref = $Ref.Replace('"', '').Trim()

    if ($Ref -cmatch '^[0-9]+$') { return @{ Site = (Get-CfSite); PageId = $Ref } }

    if ($Ref -cmatch '^(https://[^/]+)/wiki/') {
        $site = $Matches[1].ToLowerInvariant()
        # /pages/ か /folder/ の後ろで、最初の数字だけのところがページ ID（edit-v2 などは読み飛ばす）
        # フォルダも、子の一覧・親の指定（ancestors）は ページ と同じ API で扱える
        $path = ($Ref -creplace '^https://[^/]+/wiki/', '') -creplace '[?#].*$', ''
        $segs = $path.Split('/')
        $i = -1
        for ($j = 0; $j -lt $segs.Count; $j++) { if ($segs[$j] -ceq 'pages' -or $segs[$j] -ceq 'folder') { $i = $j; break } }
        if ($i -ge 0) {
            for ($j = $i + 1; $j -lt $segs.Count; $j++) {
                if ($segs[$j] -cmatch '^[0-9]+$') { return @{ Site = $site; PageId = $segs[$j] } }
                if ($segs[$j] -cnotmatch '^[a-z0-9-]+$') { break }
            }
        }
        if ($Ref -cmatch '[?&]pageId=([0-9]+)') { return @{ Site = $site; PageId = $Matches[1] } }
    }

    throw "ページの URL か ID を指定してください（/pages/<数字>/、/folder/<数字>、pageId=<数字> のどれかを含む URL。短縮 URL /wiki/x/... は不可）：$Ref"
}

# Get-CfMapValue <変数名> <ホスト名> → 値（なければ $null）
# 変数の中身は「ホスト名=値」をカンマか空白で区切ったもの。値は最初の = より後ろ全部
function Get-CfMapValue([string]$Name, [string]$HostName) {
    $raw = [Environment]::GetEnvironmentVariable($Name)
    if (-not $raw) { return $null }
    foreach ($entry in ($raw -split '[,\s]+')) {
        if (-not $entry) { continue }
        # 値は秘密情報なので、表示しない
        if ($entry -notmatch '^.+=.+$') { Write-Warning "$Name に「ホスト名=値」の形でないものがあるので無視します"; continue }
        $eq = $entry.IndexOf('=')
        if ($entry.Substring(0, $eq) -eq $HostName) { return $entry.Substring($eq + 1) }   # -eq は大文字・小文字を区別しない
    }
    return $null
}

# Get-CfAuth <ホスト名> [<メールアドレス>] → <メールアドレス>:<トークン>
function Get-CfAuth([string]$HostName, [string]$Email) {
    if (-not $Email) { $Email = Get-CfMapValue 'RAYRC_JIRA_EMAIL' $HostName }
    if (-not $Email) { $Email = Read-Host "Atlassian のメールアドレス（$HostName）" }
    $token = Get-CfMapValue 'RAYRC_JIRA_TOKEN' $HostName
    if (-not $token) {
        $secure = Read-Host "API トークン（$HostName）" -AsSecureString
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try { $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    }
    if (-not $Email -or -not $token) { throw "メールアドレスと API トークンが要ります（$HostName）" }
    return "${Email}:${token}"
}

# ConvertTo-CfQuoted <文字列> → "…"（\ と " をエスケープ。curl の設定ファイルの値と、-F のファイル名で同じ決まり）
function ConvertTo-CfQuoted([string]$Value) { '"' + $Value.Replace('\', '\\').Replace('"', '\"') + '"' }

# Invoke-CfCurl <認証> <curl の引数...> [<出力ファイル>] [<設定の行...>]
# 出力ファイルがなければ、応答を UTF-8 として読んで返す（コンソールの文字コードに左右されない）。
# 認証はプロセスの一覧に出ないよう、標準入力の設定（-K -）で渡す。
# 設定の行（例：form = "..."）も同じ標準入力で渡す。引数と違って、Windows PowerShell 5.1 でも " を含む値が崩れない
function Invoke-CfCurl([string]$Auth, [string[]]$CurlArgs, [string]$OutFile, [string[]]$ConfigLines) {
    $tmp = $null
    if (-not $OutFile) { $tmp = [IO.Path]::GetTempFileName(); $OutFile = $tmp }
    # 標準入力へは UTF-8 で書く。5.1 は既定が ASCII（日本語が ? になる）で、しかもグローバルの $OutputEncoding しか見ない
    $savedEncoding = $global:OutputEncoding
    try {
        $config = (@("user = $(ConvertTo-CfQuoted $Auth)") + @($ConfigLines | Where-Object { $_ })) -join "`n"
        $global:OutputEncoding = $CfUtf8
        $code = $config | & curl.exe -sS -L -K - -o $OutFile -w '%{http_code}' @CurlArgs
        if ($LASTEXITCODE -ne 0 -or [int]"0$code" -ge 400) {
            $detail = if (Test-Path -LiteralPath $OutFile) { [IO.File]::ReadAllText($OutFile, $CfUtf8) } else { '' }
            throw "API の呼び出しに失敗しました（HTTP $code。認証・権限・URL を確認）：$($CurlArgs[-1])`n$detail"
        }
        if ($tmp) { return [IO.File]::ReadAllText($tmp, $CfUtf8) }
    }
    finally {
        $global:OutputEncoding = $savedEncoding
        if ($tmp) { Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue }
    }
}

function Get-CfJson([string]$Auth, [string]$Url) { (Invoke-CfCurl $Auth @($Url)) | ConvertFrom-Json }

# Get-CfList <認証> <URL（? を含み、start= を除く）> → 全ページ分の results（1 件ずつ出す。受ける側は @() で包む）
function Get-CfList([string]$Auth, [string]$Url) {
    $start = 0
    do {
        $r = Get-CfJson $Auth "$Url&start=$start"
        foreach ($x in $r.results) { $x }
        $start += $r.size
    } while ($r._links.next)
}

# Get-CfChildren <認証> <サイト> <ページ ID> → 直下の子（Confluence での並び順。受ける側は @() で包む）
function Get-CfChildren([string]$Auth, [string]$Site, [string]$PageId) {
    Get-CfList $Auth "$Site/wiki/rest/api/content/$PageId/child/page?limit=100"
}
