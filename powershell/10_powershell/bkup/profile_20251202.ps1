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
