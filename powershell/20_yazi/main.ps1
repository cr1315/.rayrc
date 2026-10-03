# Ctrl + O で yazi を起動する設定
Set-PSReadLineKeyHandler -Key "Ctrl+o" -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    yazi
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
