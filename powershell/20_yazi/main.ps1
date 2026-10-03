# bash (bash/18_yazi/main.sh) と同じ libs/yazi/config を参照する
$env:YAZI_CONFIG_HOME = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\..\libs\yazi\config")

# file.exe は Git for Windows 同梱（PATH 外の usr\bin にある）
# git --exec-path は shim 経由でも実体の場所を返すので、そこから逆算する
if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitRoot = Split-Path (Split-Path (Split-Path (git --exec-path)))
    $fileExe = Join-Path $gitRoot "usr\bin\file.exe"
    if (Test-Path $fileExe) { $env:YAZI_FILE_ONE = $fileExe }
    Remove-Variable gitRoot, fileExe
}

# y: yazi 終了時のディレクトリへ cd する公式シェルラッパー（原文ママ）
# https://yazi-rs.github.io/docs/quick-start#shell-wrapper
function y {
    $tmp = (New-TemporaryFile).FullName
    yazi.exe @args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if ($cwd -and $cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container)) {
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }
    Remove-Item -Path $tmp
}

# Ctrl + O で yazi を起動する設定
# AcceptLine で空行を確定させ、移動後のディレクトリでプロンプトを再描画する
Set-PSReadLineKeyHandler -Key "Ctrl+o" -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    y
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
