
# https://chromeenterprise.google/policies/#ExtensionSettings

remove-Item HKLM:\Software\Policies\Google\Chrome\ExtensionInstallBlocklist
# there is even no this key in Chrome's Docs
remove-Item HKLM:\Software\Policies\Google\Chrome\ExtensionInstallBlacklist

remove-Item HKLM:\Software\Policies\Google\Chrome\ExtensionInstallSources
remove-item hklm:\Software\Policies\Google\Chrome\SyncTypesListDisabled


# https://docs.microsoft.com/en-us/deployedge/microsoft-edge-policies#extensions
remove-Item HKLM:\SOFTWARE\Policies\Microsoft\Edge\SyncTypesListDisabled
remove-Item HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallBlocklist

