<#
  ② 一括：zip とフォルダの配置、入れ子のたどり方、どのページに入れるか、タイトル（bulk.zsh の PowerShell 版）
    zip を扱うのはこの層だけ。ページの読み書きは ③ ページ（page.ps1）に任せる。
    「何が正か」は Get-CfDecidedTitle と Get-CfDecidedTarget の 2 つに集める。
    層の分け方と決まりは refactoring.md を参照。

  zip の配置
    <ページ ID>_<タイトル>.zip       1 ページ 1 zip（中身は ③ のページのフォルダ）
    <ページ ID>_<タイトル>/          子のページの zip を入れるフォルダ（-Recursive。孫以下も同じ）
    子の並び順は、親の page.json の children に書く（書いていない子は名前の順）
#>

Add-Type -AssemblyName System.IO.Compression.FileSystem

# Get-CfZipId <zip> → zip の名前の先頭のページ ID（なければ $null）
function Get-CfZipId([string]$Zip) {
    if ([IO.Path]::GetFileName($Zip) -cmatch '^([0-9]+)_') { return $Matches[1] }
    return $null
}

function Read-CfPageJson([string]$Dir) {
    $p = Join-Path $Dir 'page.json'
    if (Test-Path -LiteralPath $p -PathType Leaf) { return [IO.File]::ReadAllText($p, $CfUtf8) | ConvertFrom-Json }
    return $null
}

function New-CfWorkDir([string]$Prefix) {
    $dir = Join-Path ([IO.Path]::GetTempPath()) ("${Prefix}_" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $dir | Out-Null
    return $dir
}

# Get-CfDecidedTitle <-Title の値> <ページのフォルダ> <zip> <page|parent> → タイトル
# 上から順に、最初に見つかったものを使う
#   1. -Title
#   2. page.xhtml の先頭の <title>（空なら次へ）
#   3. page.json の title
#   4. ページを指定したとき：空（今のタイトルのまま）
#      親の下に入れるとき  ：zip の名前（先頭の <数字>_ を除く）
function Get-CfDecidedTitle([string]$Override, [string]$Dir, [string]$Zip, [string]$Kind) {
    if ($Override) { return $Override }

    $parsed = Get-CfPageTitle (Join-Path $Dir 'page.xhtml')
    if ($parsed -and $parsed.Title) { return $parsed.Title }

    $meta = Read-CfPageJson $Dir
    if ($meta -and $meta.title) { return [string]$meta.title }

    if ($Kind -eq 'page') { return '' }
    return [IO.Path]::GetFileNameWithoutExtension($Zip) -creplace '^[0-9]+_', ''
}

# Get-CfDecidedTarget <認証> <サイト> <page|parent> <ページ ID|親 ID> <ページのフォルダ> <タイトル>
#   → @('update', <ページ ID>) か @('create', <親 ID>)
# ページを指定したとき：そのページを更新する
# 親の下に入れるとき  ：上から順に
#   1. page.json の site が同じで、その id のページが親の直下にあれば、それを更新する（タイトルを変えても同じページ）
#   2. 親の直下に同じタイトルのページがあれば、それを更新する
#   3. どちらもなければ、親の下に作る
function Get-CfDecidedTarget([string]$Auth, [string]$Site, [string]$Kind, [string]$Ref, [string]$Dir, [string]$Title) {
    if ($Kind -eq 'page') { return @('update', $Ref) }

    $kids = @(Get-CfChildren $Auth $Site $Ref)
    $hit = $null
    $meta = Read-CfPageJson $Dir
    if ($meta -and "$($meta.site)".ToLowerInvariant() -ceq $Site -and $meta.id) {
        $hit = @($kids | Where-Object { "$($_.id)" -ceq "$($meta.id)" } | Select-Object -First 1 | ForEach-Object { $_.id })
    }
    if (-not $hit) {
        $hit = @($kids | Where-Object { $_.title -ceq $Title } | Select-Object -First 1 | ForEach-Object { $_.id })
    }
    if ($hit) { return @('update', [string]$hit[0]) }
    return @('create', $Ref)
}

# Import-CfZip <認証> <サイト> <zip> <page|parent> <ページ ID|親 ID> <-Title の値> <版のメッセージ> <prune> <recursive> → ページ ID
# zip を 1 つ取り込む。recursive なら、zip と同じ名前のフォルダの中の zip を、このページの子として取り込む
function Import-CfZip([string]$Auth, [string]$Site, [string]$Zip, [string]$Kind, [string]$Ref,
    [string]$Override, [string]$Message, [bool]$Prune, [bool]$Recursive) {
    $order = @()
    $work = New-CfWorkDir 'confluence-import'
    try {
        Write-Host "zip：$Zip"
        # UTF-8 の印のない名前も UTF-8 として読む（Info-ZIP の zip が作る zip。既定だと 5.1 は ANSI、7 は CP437 で読んで化ける）
        [IO.Compression.ZipFile]::ExtractToDirectory($Zip, $work, [Text.Encoding]::UTF8)
        $found = @(Get-ChildItem -LiteralPath $work -Recurse -Filter 'page.xhtml' -File | Where-Object { $_.Name -ceq 'page.xhtml' })
        if ($found.Count -ne 1) { throw "zip の中に page.xhtml がちょうど 1 つ必要です（見つかった数：$($found.Count)）：$Zip" }
        $dir = $found[0].DirectoryName

        $title = Get-CfDecidedTitle $Override $dir $Zip $Kind
        $target = Get-CfDecidedTarget $Auth $Site $Kind $Ref $dir $title
        $id = Import-CfPageFolder $Auth $Site $dir $target[0] $target[1] $title $Message $Prune

        if ($Recursive) {
            $meta = Read-CfPageJson $dir
            if ($meta) { $order = @($meta.children | Where-Object { $_ } | ForEach-Object { [string]$_.id }) }
        }
    }
    finally {
        Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
    }

    # 子（zip と同じ名前のフォルダの中の zip）。page.json の children の順、書いていないものは名前の順
    $kidDir = $Zip.Substring(0, $Zip.Length - [IO.Path]::GetExtension($Zip).Length)
    if ($Recursive -and (Test-Path -LiteralPath $kidDir -PathType Container)) {
        $zips = @(Get-ChildItem -LiteralPath $kidDir -Filter '*.zip' -File | Sort-Object Name | ForEach-Object { $_.FullName })
        $sorted = New-Object System.Collections.Generic.List[string]
        foreach ($k in $order) {
            foreach ($z in $zips) { if ([IO.Path]::GetFileName($z).StartsWith("${k}_", [StringComparison]::Ordinal)) { $sorted.Add($z) } }
        }
        foreach ($z in $zips) { if (-not $sorted.Contains($z)) { $sorted.Add($z) } }
        foreach ($z in $sorted) {
            Import-CfZip $Auth $Site $z 'parent' $id '' $Message $Prune $true | Out-Null
        }
    }
    return $id
}

# Export-CfZip <認証> <サイト> <ページ ID> <出力フォルダ> <force> <recursive>
# ページを <ページ ID>_<タイトル>.zip に書き出す。recursive なら、子を zip と同じ名前のフォルダに書き出す
function Export-CfZip([string]$Auth, [string]$Site, [string]$PageId, [string]$OutDir, [bool]$Force, [bool]$Recursive) {
    $info = Get-CfPageInfo $Auth $Site $PageId
    $title = $info.title
    $version = $info.version.number

    $safe = ($title -replace '[\\/:*?"<>|\s]+', '_').Trim('_')
    if ($safe.Length -gt 60) { $safe = $safe.Substring(0, 60) }
    $out = Join-Path $OutDir "${PageId}_$safe.zip"
    if ((Test-Path -LiteralPath $out) -and -not $Force) { throw "すでにあります（上書きするときは -Force）：$out" }
    Write-Host "ページ：$title（版 $version、ID $PageId）"

    $kids = @()
    if ($Recursive) { $kids = @(Get-CfChildren $Auth $Site $PageId) }

    $work = New-CfWorkDir 'confluence-export'
    try {
        $natt = Export-CfPageFolder $Auth $Site $info $work
        if ($Recursive) {
            $meta = Read-CfPageJson $work
            $meta | Add-Member -NotePropertyName children -NotePropertyValue @($kids | ForEach-Object { [ordered]@{ id = $_.id; title = $_.title } })
            Write-CfJson (Join-Path $work 'page.json') $meta
        }

        if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Force }
        [IO.Compression.ZipFile]::CreateFromDirectory($work, $out)
        Write-Host "完了（版 $version、添付 $natt 件）：$out"
    }
    finally {
        Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
    }

    # 子（zip と同じ名前のフォルダに書き出す）
    if ($Recursive -and $kids.Count) {
        $kidDir = $out.Substring(0, $out.Length - '.zip'.Length)
        New-Item -ItemType Directory -Path $kidDir -Force | Out-Null
        foreach ($kid in $kids) {
            Export-CfZip $Auth $Site ([string]$kid.id) $kidDir $Force $true
        }
    }
}

# Export-CfZipChildren <認証> <サイト> <親 ID> <出力フォルダ> <force> <recursive>
# 親（ページでもフォルダでもよい）の直下の子を、出力フォルダに 1 ページ 1 zip で書き出す。親そのものは書き出さない。
# recursive なら、孫から下は Export-CfZip と同じく、zip と同じ名前のフォルダに書き出す。
# 親の page.json がないので、子の並び順は残らない
function Export-CfZipChildren([string]$Auth, [string]$Site, [string]$ParentId, [string]$OutDir, [bool]$Force, [bool]$Recursive) {
    $kids = @(Get-CfChildren $Auth $Site $ParentId)
    if (-not $kids.Count) { Write-Host "子のページがありません（親 ID $ParentId）"; return }
    foreach ($kid in $kids) {
        Export-CfZip $Auth $Site ([string]$kid.id) $OutDir $Force $Recursive
    }
}
