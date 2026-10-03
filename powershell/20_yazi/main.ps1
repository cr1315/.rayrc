# bash (bash/18_yazi/main.sh) と同じ libs/yazi/config を参照する
$env:YAZI_CONFIG_HOME = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\..\libs\yazi\config")

# Ctrl + O で yazi を起動する設定
Set-PSReadLineKeyHandler -Key "Ctrl+o" -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    yazi
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
