
# POWERSHELL

## list all routes for up link
Get-NetRoute -AddressFamily ipv4 | ? { $_.ifIndex -in ((Get-NetIPInterface -AddressFamily ipv4 | ? { $_.ConnectionState -eq "Connected" } | select ifIndex).ifIndex) } | select -property ifIndex, DestinationPrefix, @{Name = "mask"; Expression = { [int]($_.DestinationPrefix -replace '.*/(\d+)$', '$1') } }, NextHop, RouteMetric, interfaceMetric | sort ifindex, @{Expression = "mask"; Descending = $True }, routemetric, interfaceMetric, DestinationPrefix | ft

New-NetRoute -PolicyStore ActiveStore -DestinationPrefix "192.168.0.0/20" -NextHop "10.10.34.1" -InterfaceIndex 4


## start-process like C#
$process = New-Object -TypeName System.Diagnostics.Process
$process.StartInfo.FileName = "tree.com"
$process.StartInfo.UseShellExecute = $false
$process.StartInfo.RedirectStandardOutput = $true
$process.StartInfo.RedirectStandardError = $true
$process.StartInfo.StandardOutputEncoding = [System.Text.Encoding]::GetEncoding(437)
$process.StartInfo.WorkingDirectory = pwd
$process.Start()
$process.StandardOutput.ReadToEnd()
$process.WaitForExit()


## show Encoding
OutputEncoding: $OutputEncoding
[Console]::OutputEncoding: $([Console]::OutputEncoding)
[Console]::IutputEncoding: $([Console]::IutputEncoding)
[cultureinfo]::CurrentCulture.TextInfo.OEMCodePage: $([cultureinfo]::CurrentCulture.TextInfo.OEMCodePage)
