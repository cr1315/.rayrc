######################################################################
#
# Entry for Windows: install the modules and register .rayrc in the PowerShell profile
#
#   cd $env:USERPROFILE\.rayrc; . .\install.ps1
#   . .\install.ps1 -Filter text,bat      # only some modules (same as bash --filter)
#
# The work is done by src/install.ps1. It is invoked with & (its own
# scope) so that its Set-StrictMode / $ErrorActionPreference do not leak
# into the caller's session even when this file is dot-sourced.
#
######################################################################
& (Join-Path $PSScriptRoot 'src/install.ps1') @args
