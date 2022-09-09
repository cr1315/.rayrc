

function safelyRemoveRegistryKey($path) {
    if (test-path "${path}") {
        remove-item "${path}"
    }
}

# https://docs.microsoft.com/en-us/deployedge/microsoft-edge-policies#extensions
safelyRemoveRegistryKey HKLM:\SOFTWARE\Policies\Microsoft\Edge\SyncTypesListDisabled
safelyRemoveRegistryKey HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallBlocklist

set-ItemProperty hklm:\SOFTWARE\Policies\Microsoft\Edge -name "AuthSchemes" -value "basic, ntlm, negotiate"
set-ItemProperty hklm:\SOFTWARE\Policies\Microsoft\Edge -name "BasicAuthOverHttpEnabled" -value 1
set-ItemProperty hklm:\SOFTWARE\Policies\Microsoft\Edge -name "ImportSavedPasswords" -value 1
set-ItemProperty hklm:\SOFTWARE\Policies\Microsoft\Edge -name "PasswordManagerEnabled" -value 1


function safelyRemoveRegistryProperty() {}
remove-ItemProperty hklm:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist -name 1 -ea Continue
remove-ItemProperty hklm:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist -name 4 -ea Continue







# https://chromeenterprise.google/policies/#ExtensionSettings

safelyRemoveRegistryKey HKLM:\Software\Policies\Google\Chrome\ExtensionInstallBlocklist
# there is even no this key in Chrome's Docs
safelyRemoveRegistryKey HKLM:\Software\Policies\Google\Chrome\ExtensionInstallBlacklist

safelyRemoveRegistryKey HKLM:\Software\Policies\Google\Chrome\ExtensionInstallSources
safelyRemoveRegistryKey hklm:\Software\Policies\Google\Chrome\SyncTypesListDisabled


set-ItemProperty hklm:\SOFTWARE\Policies\Google\Chrome -name "ImportSavedPasswords" -value 1
set-ItemProperty hklm:\SOFTWARE\Policies\Google\Chrome -name "PasswordManagerEnabled" -value 1
