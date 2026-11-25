<#
  Confluence Cloud のページを zip で取り込む・書き出す関数（main.zsh の PowerShell 版。決まりは zsh 版と同じ）

    Import-ConfluencePage 330137615_promote.zip          # zip の中身でページを更新する
    Import-ConfluencePage -p 330137615 a.zip b.zip       # 親の子として取り込む（同じタイトルの子があれば更新、なければ作る）
    Export-ConfluencePage 330137615                      # ページを zip に書き出す（URL でもよい）
    Export-ConfluencePage -r 330137615                   # 子孫のページも書き出す
    Export-ConfluencePage -p 330137615 -r                # 親は書き出さず、子孫だけを書き出す（フォルダの下も）

  オプションは zsh 版の 1 文字のもの（-u -p -t -m -e -r -o -f）も、そのまま使える。

  環境変数（なければ、そのつど入力を求める）
    RAYRC_JIRA_BASE_URL  ページ ID だけを渡したときのサイトの URL（例：https://xxx.atlassian.net）
    RAYRC_JIRA_EMAIL     ホスト名ごとの Atlassian のメールアドレス
    RAYRC_JIRA_TOKEN     ホスト名ごとの API トークン（https://id.atlassian.com/manage-profile/security/api-tokens）

    RAYRC_JIRA_EMAIL と RAYRC_JIRA_TOKEN は「ホスト名=値」をカンマか空白（改行でもよい）で区切って並べる。
    値は最初の = より後ろ全部（トークンが = を含んでもよい）。ホスト名の大文字・小文字は区別しない。
      RAYRC_JIRA_EMAIL = 'xxx.atlassian.net=me@example.com,yyy.atlassian.net=me@example.org'
      RAYRC_JIRA_TOKEN = 'xxx.atlassian.net=ATATT...,yyy.atlassian.net=ATATT...'
    秘密情報なので、このリポジトリの外で設定すること。

  使うコマンド：curl.exe（zip は .NET の System.IO.Compression で扱う）
  Windows PowerShell 5.1 と PowerShell 7 の両方で動くように書いている。

  層（refactoring.md を参照）
    ① main.ps1  CLI：オプションを読んで確かめ、② に渡す
    ② bulk.ps1  一括：zip とフォルダの配置、入れ子、どのページに入れるか、タイトル
    ③ page.ps1  ページ：ページのフォルダと Confluence のページ 1 枚を行き来させる
    ④ api.ps1   共通：認証、curl、一覧、URL の読み取り
  ②〜④ の関数は、このモジュールの中に閉じ込める（外に出すのは Import-ConfluencePage と Export-ConfluencePage だけ）。
#>
New-Module -Name Confluence -ArgumentList $(if ($__rayrc_ctl_dir) { $__rayrc_ctl_dir } else { $PSScriptRoot }) -ScriptBlock {
    param([string]$CtlDir)

    . (Join-Path $CtlDir 'api.ps1')
    . (Join-Path $CtlDir 'page.ps1')
    . (Join-Path $CtlDir 'bulk.ps1')

    # ---- 取り込み ----

    function Import-ConfluencePage {
        <#
      .SYNOPSIS  zip（page.xhtml と図）の中身で、Confluence のページを更新する
      .DESCRIPTION
        1. 本文が参照している図を添付に反映する。中身が同じ図は上げない（添付のコメントの sha256 で比べる）
        2. この関数が上げた図（コメントが sha256: で始まる）のうち、本文が参照しなくなったものを削除する（-NoPrune で無効）
        3. 本文を page.xhtml で丸ごと置き換える。先頭の <title> はタイトルの場所なので、本文からは除く
        タイトル（上から順に、最初に見つかったもの）
          -Title → page.xhtml の先頭の <title> → page.json の title
                 → ページを更新するなら今のまま、親の下に入れるなら zip の名前（先頭の <数字>_ を除く）
        取り込む先
          -Url も -Parent もなし  zip の名前の先頭の数字（<ページ ID>_<名前>.zip）のページ
          -Url (-u)               指定したページ（zip が 1 つのときだけ）
          -Parent (-p)            指定したページの子。上から順に
                                  page.json の site が同じで、その id の子があれば更新（タイトルを変えても同じページ）
                                  → 同じタイトルの子があれば更新 → なければ作る
        -Recursive (-r)  zip と同じ名前のフォルダがあれば、その中の zip をそのページの子として取り込む
                         （-Parent と同じ決まり。孫以下も同じ）
        -Title (-t) は zip が 1 つのときだけ使える
        zip は一時フォルダの下に展開し、終わったら（失敗しても）消す
      .EXAMPLE  Import-ConfluencePage 330137615_promote.zip
      .EXAMPLE  Import-ConfluencePage .\sonar.zip -Url https://xxx.atlassian.net/wiki/spaces/KEY/pages/123/Title
      .EXAMPLE  Import-ConfluencePage -p 330137615 -r a.zip b.zip
    #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments)][Alias('Input')][string[]]$InputFile,
            [Alias('u', 'PageId')][string]$Url,           # URL かページ ID
            [Alias('p')][string]$Parent,                  # 親の URL かページ ID
            [Alias('t')][string]$Title,
            [Alias('m')][string]$Message = 'Import-ConfluencePage で更新',
            [Alias('e')][string]$Email,
            [Alias('r')][switch]$Recursive,
            [switch]$NoPrune
        )
        $ErrorActionPreference = 'Stop'

        $zips = @(foreach ($z in $InputFile) {
                if (-not (Test-Path -LiteralPath $z -PathType Leaf)) { throw "ファイルがありません：$z" }
                $full = (Resolve-Path -LiteralPath $z).ProviderPath
                if ([IO.Path]::GetExtension($full) -ne '.zip') { throw "zip を指定してください：$full" }
                $full
            })
        if ($Url -and $Parent) { throw "-Url と -Parent は一緒に使えません" }
        if ($zips.Count -gt 1 -and ($Url -or $Title)) { throw "-Url と -Title は zip が 1 つのときだけ使えます" }
        Assert-CfCommand 'curl.exe'

        # 取り込む先：-Parent なら親の下（parent）、そうでなければ -Url か zip の名前のページ（page）
        $kind = 'page'
        if ($Parent) {
            $p = Resolve-CfPage $Parent
            $site = $p.Site
            $kind = 'parent'
            $refs = @($zips | ForEach-Object { $p.PageId })
        }
        else {
            $ref = $Url
            if (-not $ref -and $zips.Count -eq 1 -and -not (Get-CfZipId $zips[0])) {
                $ref = Read-Host "反映先のページの URL か ID（zip の名前を <ページ ID>_<名前>.zip にすれば省略できる）"
            }
            if ($ref) {
                $p = Resolve-CfPage $ref
                $site = $p.Site
                $refs = @($p.PageId)
            }
            else {
                $refs = @(foreach ($z in $zips) {
                        $zid = Get-CfZipId $z
                        if (-not $zid) { throw "zip の名前からページ ID が読めません（<ページ ID>_<名前>.zip にするか、-Parent で親を指定する）：$z" }
                        $zid
                    })
                $site = Get-CfSite
            }
        }
        $auth = Get-CfAuth ($site -replace '^https://', '') $Email

        for ($i = 0; $i -lt $zips.Count; $i++) {
            Import-CfZip $auth $site $zips[$i] $kind $refs[$i] $Title $Message (-not $NoPrune) $Recursive.IsPresent | Out-Null
        }
    }

    # ---- 書き出し ----

    function Export-ConfluencePage {
        <#
      .SYNOPSIS  Confluence のページを zip に書き出す（page.xhtml・page.json・添付ファイル）
      .DESCRIPTION
        zip の名前は「<ページ ID>_<タイトル>.zip」。そのまま Import-ConfluencePage に渡せる
        - page.xhtml：本文（ストレージ形式）。先頭に <title>タイトル</title> の 1 行を足す（取り込むときにタイトルになる）
        - page.json ：ID、タイトル、版、スペース、サイト、書き出した日時、添付の一覧（-Recursive なら子の一覧も）
        - 添付ファイル：ページのすべての添付（今の版）
        -OutputDir (-o) を省略するとカレントディレクトリに書き出す。すでにあれば -Force (-f) で上書きする
        -Recursive (-r)  子孫のページも書き出す。子は zip と同じ名前のフォルダに入れる（孫以下も同じ）
                         Import-ConfluencePage -Recursive に渡すと、同じ入れ子で取り込める
        -Parent (-p)     指定したページ（フォルダでもよい）の直下の子を、出力フォルダに書き出す。親そのものは書き出さない
                         -Recursive も付けると子孫全部。Import-ConfluencePage -p <親> -r <出力フォルダ>\*.zip に渡すと、同じ形で取り込める
                         親の page.json がないので、子の並び順は残らない（新しく作るときは zip の名前の順になる）
                         ページの指定とは一緒に使えない
      .EXAMPLE  Export-ConfluencePage 330137615
      .EXAMPLE  Export-ConfluencePage https://xxx.atlassian.net/wiki/spaces/KEY/pages/330137615/promote -OutputDir ~\Downloads
      .EXAMPLE  Export-ConfluencePage -r 330137615
      .EXAMPLE  Export-ConfluencePage -p https://xxx.atlassian.net/wiki/spaces/KEY/folder/207683588 -r
    #>
        [CmdletBinding()]
        param(
            [Parameter(Position = 0)][Alias('Url', 'PageId')][string]$Page,
            [Alias('p')][string]$Parent,   # 親の URL かページ ID
            [Alias('o')][string]$OutputDir = (Get-Location).ProviderPath,
            [Alias('e')][string]$Email,
            [Alias('f')][switch]$Force,
            [Alias('r')][switch]$Recursive
        )
        $ErrorActionPreference = 'Stop'

        if ($Page -and $Parent) { throw "ページの指定と -Parent は一緒に使えません" }
        if (-not $Page -and -not $Parent) { throw "ページの URL か ID（子だけを書き出すなら -Parent）を指定してください" }
        if (-not (Test-Path -LiteralPath $OutputDir -PathType Container)) { throw "出力フォルダがありません：$OutputDir" }
        Assert-CfCommand 'curl.exe'

        $p = Resolve-CfPage $(if ($Parent) { $Parent } else { $Page })
        $auth = Get-CfAuth ($p.Site -replace '^https://', '') $Email
        $out = (Resolve-Path -LiteralPath $OutputDir).ProviderPath
        if ($Parent) { Export-CfZipChildren $auth $p.Site $p.PageId $out $Force.IsPresent $Recursive.IsPresent }
        else { Export-CfZip $auth $p.Site $p.PageId $out $Force.IsPresent $Recursive.IsPresent }
    }

    Export-ModuleMember -Function Import-ConfluencePage, Export-ConfluencePage
} | Import-Module -Global
