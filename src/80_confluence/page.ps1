<#
  ③ ページ：ページのフォルダと Confluence のページ 1 枚を行き来させる（page.zsh の PowerShell 版）
    ページのフォルダ（zip を展開したもの）
      page.xhtml  本文（ストレージ形式）。先頭の <title> はタイトルの場所で、本文には入れない
                  （書き出すときは <title>タイトル</title> の 1 行を先頭に足し、取り込むときは取り除く）
      page.json   id、title、version、space、site、exportedAt、attachments
                  （children は ② 一括が足す）
      <図>        本文が ri:attachment で参照するファイル
    言われたページを、言われたとおりに読み書きする。zip・入れ子・どのページに入れるかは知らない。
    層の分け方は refactoring.md を参照。
#>

# ConvertFrom-CfHtml <文字列> → &amp; や &#12354; を戻したもの
# 戻すのは amp・lt・gt・quot・apos と数値の参照だけ。ほかの名前の参照（&nbsp; など）はそのまま残す（zsh 版と同じ）
function ConvertFrom-CfHtml([string]$Text) {
    [regex]::Replace($Text, '&(#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z]+);', {
            param($m)
            $ent = $m.Groups[1].Value
            switch -CaseSensitive ($ent) {
                'amp' { return '&' }
                'lt' { return '<' }
                'gt' { return '>' }
                'quot' { return '"' }
                'apos' { return "'" }
            }
            try {
                if ($ent -cmatch '^#[xX]') { return [char]::ConvertFromUtf32([Convert]::ToInt32($ent.Substring(2), 16)) }
                if ($ent -cmatch '^#') { return [char]::ConvertFromUtf32([int]$ent.Substring(1)) }
            }
            catch { }
            return $m.Value
        })
}

# ConvertTo-CfHtml <文字列> → < > & ' " をエスケープしたもの（jq の @html と同じ）
function ConvertTo-CfHtml([string]$Text) {
    $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace("'", '&#39;').Replace('"', '&quot;')
}

# Get-CfPageTitle <page.xhtml> → @{ Title = <タイトル>; Body = <<title> を除いた本文> }（先頭が <title> でなければ $null）
# 本文の先頭（BOM と空白は飛ばす）が <title>…</title> なら、その文字（&amp; などを戻し、空白を詰めたもの）を返す。
# 文字が空でも返す（<title> は本文から除く。タイトルに使うかどうかは呼ぶ側が決める）
function Get-CfPageTitle([string]$Path) {
    $body = [IO.File]::ReadAllText($Path, $CfUtf8).TrimStart([char]0xFEFF).TrimEnd("`n")
    $m = [regex]::Match($body, '\A\s*<title(?:\s[^>]*)?>')
    if (-not $m.Success) { return $null }
    $rest = $body.Substring($m.Length)
    $end = $rest.IndexOf('</title>', [StringComparison]::Ordinal)
    if ($end -lt 0) { return $null }
    $text = ((ConvertFrom-CfHtml $rest.Substring(0, $end)) -replace '\s+', ' ').Trim(' ')
    return @{ Title = $text; Body = $rest.Substring($end + '</title>'.Length).TrimStart() }
}

# Get-CfPageInfo <認証> <サイト> <ページ ID> → ページ（本文・版・スペース付き）
function Get-CfPageInfo([string]$Auth, [string]$Site, [string]$PageId) {
    Get-CfJson $Auth "$Site/wiki/rest/api/content/${PageId}?expand=body.storage,version,space"
}

# Write-CfJson <ファイル> <オブジェクト>（UTF-8、BOM なし）
function Write-CfJson([string]$Path, $Object) {
    [IO.File]::WriteAllText($Path, ($Object | ConvertTo-Json -Depth 8), $CfUtf8)
}

# Export-CfPageFolder <認証> <サイト> <ページ> <フォルダ> → 添付の数
# ページを、空のフォルダに書き出す（page.xhtml・page.json・添付）。page.xhtml の先頭には <title>タイトル</title> の 1 行を足す
function Export-CfPageFolder([string]$Auth, [string]$Site, $Info, [string]$Dir) {
    $id = $Info.id
    [IO.File]::WriteAllText((Join-Path $Dir 'page.xhtml'),
        "<title>$(ConvertTo-CfHtml $Info.title)</title>`n" + $Info.body.storage.value, $CfUtf8)

    $atts = @(Get-CfList $Auth "$Site/wiki/rest/api/content/$id/child/attachment?limit=100&expand=metadata")
    $n = 0
    foreach ($a in $atts) {
        Write-Host "添付：$($a.title)"
        $n++
        $tmp = Join-Path $Dir ".dl_$n"   # 古い curl.exe（Unicode なし）でも通るよう、日本語のパスを渡さない
        Invoke-CfCurl $Auth @("$Site/wiki$($a._links.download)") $tmp | Out-Null
        Move-Item -LiteralPath $tmp -Destination (Join-Path $Dir $a.title) -Force
    }

    Write-CfJson (Join-Path $Dir 'page.json') ([ordered]@{
            id = $id; title = $Info.title; version = $Info.version.number; space = $Info.space.key
            site = $Site; exportedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
            attachments = @($atts | ForEach-Object { [ordered]@{ title = $_.title; mediaType = $_.extensions.mediaType; comment = $_.metadata.comment } })
        })
    return $atts.Count
}

# Send-CfAttachment <認証> <添付の URL> <ファイル> <添付の名前> <コメント>
# 添付を上げる（同じ名前があれば新しい版になる）。-F は、5.1 でも " が崩れないよう標準入力の設定（form = ...）で渡す。
# curl.exe は設定の中の日本語のパスを開けないので、ASCII の名前の写し（.up）を作業フォルダからの相対パスで渡し、
# 本当の名前は filename= で渡す（こちらは開かずに送るだけなので、UTF-8 のまま届く）。
# 名前は "" で囲む（; や , を含んでもよいように）
function Send-CfAttachment([string]$Auth, [string]$Url, [string]$File, [string]$Name, [string]$Comment) {
    $up = '.up_' + [guid]::NewGuid().ToString('N').Substring(0, 8)
    $dir = Split-Path -Parent $File
    Copy-Item -LiteralPath $File -Destination (Join-Path $dir $up)
    Push-Location -LiteralPath $dir   # curl.exe は今の場所を作業フォルダにして起動する
    try {
        $form = 'file=@' + (ConvertTo-CfQuoted $up) + ';filename=' + (ConvertTo-CfQuoted $Name)
        Invoke-CfCurl $Auth @("-X", "PUT", "-H", "X-Atlassian-Token: no-check",
            "--form-string", "comment=$Comment", "--form-string", "minorEdit=true", $Url) -ConfigLines @("form = $(ConvertTo-CfQuoted $form)") | Out-Null
    }
    finally {
        Pop-Location
        Remove-Item -LiteralPath (Join-Path $dir $up) -ErrorAction SilentlyContinue
    }
}

# Import-CfPageFolder <認証> <サイト> <フォルダ> <update|create> <ページ ID|親 ID> <タイトル> <版のメッセージ> <prune> → ページ ID
#   update：ページ ID のページの本文を置き換える。タイトルが空なら今のまま
#   create：親 ID の下にページを作る（タイトルは必ず要る）
# 本文の先頭の <title> は、タイトルの場所なので取り除いて送る（タイトルに使うかどうかは呼ぶ側が決める）。
# どちらも、本文が参照する図を添付に反映する。
#   - 中身が同じ図は上げない（添付のコメントの sha256 で比べる）
#   - prune なら、この関数が上げた図（コメントが sha256: で始まる）のうち、本文が参照しなくなったものを消す
function Import-CfPageFolder([string]$Auth, [string]$Site, [string]$Dir, [string]$Mode, [string]$Target,
    [string]$Title, [string]$Message, [bool]$Prune) {
    $api = "$Site/wiki/rest/api"
    $json = Join-Path $Dir '.payload.json'

    # 本文（先頭の <title> を除く。BOM も除く）
    $parsed = Get-CfPageTitle (Join-Path $Dir 'page.xhtml')
    $body = if ($parsed) { $parsed.Body } else { [IO.File]::ReadAllText((Join-Path $Dir 'page.xhtml'), $CfUtf8).TrimStart([char]0xFEFF) }

    # 図（ページに書き込む前に、本文が参照している図がそろっているかを確かめる）
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    $wanted = @(foreach ($m in [regex]::Matches($body, 'ri:attachment ri:filename="([^"]+)"')) {
            $name = ConvertFrom-CfHtml $m.Groups[1].Value
            if ($seen.Add($name)) { $name }
        })
    $missing = @($wanted | Where-Object { -not (Test-Path -LiteralPath (Join-Path $Dir $_)) })
    if ($missing) { throw "本文が参照している図がありません：$($missing -join ', ')" }

    # ページ（作るときは本文ごと作る。図はこのあと上げる）
    switch ($Mode) {
        'update' {
            $id = $Target
            $cur = Get-CfJson $Auth "$api/content/${id}?expand=version"
            $version = [int]$cur.version.number
            if (-not $Title) { $Title = $cur.title }
            Write-Host "ページ：$($cur.title)（版 $version、ID $id）"
            if ($Title -cne $cur.title) { Write-Host "タイトル：$($cur.title) → $Title" }
        }
        'create' {
            $space = (Get-CfJson $Auth "$api/content/${Target}?expand=space").space.key
            Write-CfJson $json ([ordered]@{
                    type = 'page'; title = $Title; space = @{ key = $space }; ancestors = @(@{ id = $Target })
                    body = @{ storage = @{ value = $body; representation = 'storage' } }
                })
            $id = (Invoke-CfCurl $Auth @("-X", "POST", "-H", "Content-Type: application/json; charset=utf-8",
                    "--data-binary", "@$json", "$api/content") | ConvertFrom-Json).id
            Write-Host "ページ：$Title（新しく作成、ID $id、親 ID $Target）"
        }
        default { throw "update か create を指定してください：$Mode" }
    }

    # 図（添付の名前は大文字・小文字を区別する）
    $remote = New-Object System.Collections.Hashtable ([StringComparer]::Ordinal)
    foreach ($a in (Get-CfList $Auth "$api/content/$id/child/attachment?limit=100&expand=metadata")) { $remote[$a.title] = $a }
    foreach ($name in $wanted) {
        $file = (Resolve-Path -LiteralPath (Join-Path $Dir $name)).ProviderPath
        $comment = "sha256:" + (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($remote.ContainsKey($name) -and "$($remote[$name].metadata.comment)" -ceq $comment) { Write-Host "図：$name（変更なし）"; continue }
        Write-Host "図：$name（アップロード）"
        Send-CfAttachment $Auth "$api/content/$id/child/attachment" $file $name $comment
    }
    if ($Prune) {
        foreach ($t in @($remote.Keys)) {
            if ("$($remote[$t].metadata.comment)" -clike 'sha256:*' -and $wanted -cnotcontains $t) {
                Write-Host "図：$t（本文が参照しなくなったので削除）"
                Invoke-CfCurl $Auth @("-X", "DELETE", "$api/content/$($remote[$t].id)") | Out-Null
            }
        }
    }

    # 本文（作ったページは、作ったときに入れてある）
    if ($Mode -eq 'create') {
        Write-Host "完了（新しく作成）：$Site/wiki/pages/viewpage.action?pageId=$id"
    }
    else {
        Write-CfJson $json ([ordered]@{
                id = $id; type = 'page'; title = $Title
                version = [ordered]@{ number = $version + 1; message = $Message }
                body = @{ storage = @{ value = $body; representation = 'storage' } }
            })
        Invoke-CfCurl $Auth @("-X", "PUT", "-H", "Content-Type: application/json; charset=utf-8",
            "--data-binary", "@$json", "$api/content/$id") | Out-Null
        Write-Host "完了（版 $($version + 1)）：$Site/wiki/pages/viewpage.action?pageId=$id"
    }
    return $id
}
