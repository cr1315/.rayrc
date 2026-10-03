# repo 管理のテーマを直接指定する（$env:POSH_THEMES_PATH には依存しない）
$ompConfig = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\..\libs\ohmyposh\config\catppuccin.omp.json")

# install より先にプロファイルが読まれても、エラーにせず素のプロンプトのまま進む
if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path $ompConfig)) {
    & ([ScriptBlock]::Create((oh-my-posh init pwsh --config $ompConfig --print) -join "`n"))
}
Remove-Variable ompConfig
