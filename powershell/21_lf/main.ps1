# bash (bash/10_viewer/48_lf/main.sh) と同じ libs/viewer/lf を参照する
#   - colors / icons : LF_CONFIG_HOME 経由で bash と共有
#   - lfrc           : bash 用は set shell bash 前提なので、Windows 用の lfrc.windows を -config で差し替える
#   - previewer      : lfrc では絶対パスを組み立てられないので -command で渡す
#   - marks / history: LF_DATA_HOME で libs/viewer/lf/data (gitignore 済み) に置く

# 1. lf.exe の実体パスを解決（fzf と同じく Scoop の shim を経由せず直接起動する）
$scoopRoot = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $HOME 'scoop' }
$lfExe = Join-Path $scoopRoot 'apps\lf\current\lf.exe'
if (-not (Test-Path -LiteralPath $lfExe -PathType Leaf)) {
    $lfExe = (Get-Command lf.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1).Source
}

# 未インストールなら何も定義しない（Ctrl + O も素の PSReadLine のまま）
if (-not $lfExe) {
    Remove-Variable scoopRoot, lfExe
    return
}

$lfDir         = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\..\libs\viewer\lf")
$lfConfigHome  = Join-Path $lfDir 'config'
$lfDataHome    = Join-Path $lfDir 'data'
$lfConfig      = Join-Path $lfConfigHome 'lf\lfrc.windows'
$lfPreviewer   = Join-Path $lfConfigHome 'lf\lf-previewer.cmd'

# 2. lf: 設定を差し替えて起動するラッパー
#    LF_CONFIG_HOME を常時 export しないのは、素の lf.exe が bash 用 lfrc を拾うのを防ぐため。
#    bash 側も XDG_* をこの呼び出しの間だけ渡している
#    GetNewClosure で上のパスを閉じ込め、グローバル変数を残さない
${function:lf} = {
    $saved = $env:LF_CONFIG_HOME, $env:LF_DATA_HOME
    $env:LF_CONFIG_HOME = $lfConfigHome
    $env:LF_DATA_HOME = $lfDataHome
    try {
        & $lfExe -config $lfConfig -command "set previewer '$lfPreviewer'" @args
    }
    finally {
        $env:LF_CONFIG_HOME, $env:LF_DATA_HOME = $saved
    }
}.GetNewClosure()

Remove-Variable scoopRoot, lfExe, lfDir, lfConfigHome, lfDataHome, lfConfig, lfPreviewer

# 3. lfcd: lf 終了時のディレクトリへ cd する（../../libs/viewer/lf/config/templates/lfcd.ps1 相当）
function lfcd {
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        # 配列で渡すのは、-last-dir-path=... をパラメーター扱いさせず文字列のまま lf.exe に届けるため
        $lfArgs = @('-last-dir-path', $tmp) + $args
        lf @lfArgs
        $dir = [System.IO.File]::ReadAllText($tmp).TrimEnd("`r", "`n")
        if ($dir -and $dir -ne $PWD.ProviderPath -and (Test-Path -LiteralPath $dir -PathType Container)) {
            Set-Location -LiteralPath $dir
        }
    }
    finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

# 4. Ctrl + O で lfcd を起動する（20_yazi から移した）
#    終了後、移動後のディレクトリでプロンプトをその場で再描画する
Set-PSReadLineKeyHandler -Chord Ctrl+o -BriefDescription lfcd -Description 'lf で移動し、終了時のディレクトリへ cd する' -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    lfcd
    # oh-my-posh の streaming モードは、自前の Enter ハンドラーを通らない限り
    # キャッシュ済みの (移動前の) プロンプトを返す。AcceptLine を直接呼ぶと
    # それを素通りするため、公式の再描画関数でキャッシュを捨てて描き直す
    # https://ohmyposh.dev/docs/faq#repaint-the-prompt-on-demand
    if (Get-Command Invoke-PoshPromptRepaint -ErrorAction SilentlyContinue) {
        Invoke-PoshPromptRepaint
    }
    else {
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    }
}
