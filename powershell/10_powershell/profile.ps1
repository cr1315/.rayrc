# aliases
sal ll ls
sal grep sls


# posh
Import-Module posh-git
Import-Module oh-my-posh
Set-Theme Paradox
# $ThemeSettings.PromptSymbols.VirtualEnvSymbol = "ENV"
# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}


# Work around an RS5/PSReadline-2.0.0+beta2 bug (Spacebar is not marked 'essential')
Set-PSReadlineKeyHandler "Shift+SpaceBar" -ScriptBlock {
        [Microsoft.Powershell.PSConsoleReadLine]::Insert(' ')
}
Import-Module PSReadLine


# custom functions
function iswfpack {
  rm *.zip
  $pwdName = (gi $pwd).name
  ls -directory | %{Compress-Archive $_.name ($_.name+".zip")}
  ls -file | Compress-Archive -dest ($pwdName+".zip")
}

function restart-anyconnect {
  cat "C:\Users\taihang.lei\AppData\Local\Cisco\Cisco AnyConnect Secure Mobility Client\connect.txt" | & "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe" '-s'
}

