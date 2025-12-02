######################################################################
## Aliases
######################################################################
sal ll ls
sal grep sls


######################################################################
## oh-my-posh initialization
######################################################################
## no longer need this anymore!!? MUCH MORE FASTER NOW!!
# Import-Module posh-git

## was a old way to init oh-my-posh
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json"
& ([ScriptBlock]::Create((oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\catppuccin.omp.json" --print) -join "`n"))


######################################################################
## KDDI custom functions
######################################################################
# function iswfpack {
#   rm *.zip
#   $pwdName = (gi $pwd).name
#   ls -directory | %{Compress-Archive $_.name ($_.name+".zip")}
#   ls -file | Compress-Archive -dest ($pwdName+".zip")
# }

# function restart-anyconnect {
#   cat "C:\Users\taihang.lei\AppData\Local\Cisco\Cisco AnyConnect Secure Mobility Client\connect.txt" | & "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe" '-s'
# }


######################################################################
## Chocolatey Profile
######################################################################
# $ThemeSettings.PromptSymbols.VirtualEnvSymbol = "ENV"
# Chocolatey profile
# $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
# if (Test-Path($ChocolateyProfile)) {
#   Import-Module "$ChocolateyProfile"
# }


######################################################################
## BOOTSTRAP my .rayrc
######################################################################
if (test-path "$env:USERPROFILE/.rayrc") {
  . "$env:USERPROFILE/.rayrc/powershell/main.ps1"
}
