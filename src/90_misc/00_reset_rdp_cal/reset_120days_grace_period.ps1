# Define the path to the RDS grace period registry key
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\GracePeriod"

# Check if the registry key exists
if (Test-Path $registryPath) {
    try {
        # Take ownership of the registry key
        takeown /f $registryPath /r /d y
        # Assign full control permissions to the Administrators group
        $acl = Get-Acl $registryPath
        $permission = "Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
        $accessRule = New-Object System.Security.AccessControl.RegistryAccessRule $permission
        $acl.SetAccessRule($accessRule)
        Set-Acl $registryPath $acl

        # Remove the registry key
        Remove-Item -Path $registryPath -Recurse
        Write-Host "The RDS Grace Period registry key has been successfully removed."
    }
    catch {
        Write-Error "An error occurred while removing the RDS Grace Period registry key: $_"
    }
}
else {
    Write-Host "The RDS Grace Period registry key does not exist. No action is necessary."
}

# Restart the Remote Desktop Licensing service
try {
    Restart-Service TermService -Force
    Write-Host "The Remote Desktop Services have been restarted successfully."
}
catch {
    Write-Error "An error occurred while restarting the Remote Desktop Services: $_"
}
