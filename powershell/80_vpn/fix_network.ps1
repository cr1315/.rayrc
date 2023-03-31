$stgOvpn = "2700_downloaded-client-config-tcpver"
$devOvpn = "arise-cdx"


#######################################################################
# first of all, we need to elevate outself to be ADMINISTRATOR!
#######################################################################
function elevate-self {
  [OutputType([Void])]
  [CmdletBinding()]
  param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][String]$self)

  if (! ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
      IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    # Relaunch as an elevated process:
    Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList "-noexit", "-ExecutionPolicy Bypass", $self
    exit
  }
}

#######################################################################
# main
#######################################################################
function main {
  disconnect-all
  connect-stgOvpn
  Start-Sleep -Seconds 4
  prepare-gateway
  Start-Sleep -Seconds 4
  connect-anyConnect
  # Read-Host -Prompt "Press any key to continue:"
}

#######################################################################
# first disconnect all
#######################################################################
function disconnect-all {
@"
  #######################################################################
  #
  # clear all connections anyway
  #
  #######################################################################
"@

  & "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe" 'disconnect'
  & 'C:\Program Files\OpenVPN\bin\openvpn-gui.exe' "--command", "disconnect_all"
}

############################################################################
# wait a 'pattern' from file
############################################################################
function wait-pattern {
  [OutputType([Void])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][object]$file,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][String]$pattern,
    [ValidateNotNullOrEmpty()][int]$timeout = 30
  )

  try {
    $timer = [Diagnostics.Stopwatch]::StartNew()
    while ($timer.Elapsed.TotalSeconds -lt $timeout) {
      Start-Sleep -Seconds 1
      $totalSecs = [math]::Round($timer.Elapsed.TotalSeconds, 0)

      if ((select-string $pattern $file).count -ge 1) {
        break
      }

      Write-Verbose -Message "Still waiting after [$totalSecs] seconds.."
    }
    $timer.Stop()
    if ($timer.Elapsed.TotalSeconds -gt $timeout) {
      throw 'Action did not complete before timeout period!'
    } else {
      Write-Verbose -Message 'Action completed before timeout period.'
    }
  } catch {
    Write-Error -Message $_.Exception.Message
  }
}

#######################################################################
# connect the stg openvpn next
#######################################################################
function connect-stgOvpn {
@"
  #######################################################################
  #
  # next, connect to stg jump server network
  #
  #######################################################################
"@

  Start-Sleep -Seconds 1
  clc "${home}\OpenVPN\log\${stgOvpn}.log"
  & 'C:\Program Files\OpenVPN\bin\openvpn-gui.exe' "--connect", $stgOvpn
  wait-pattern "${home}\OpenVPN\log\${stgOvpn}.log" 'Initialization Sequence Completed'
}

#######################################################################
#
#######################################################################
function clear-trash {
  Remove-NetRoute -DestinationPrefix 0.0.0.0/1 -Confirm:$False
  Remove-NetRoute -DestinationPrefix 128.0.0.0/1 -Confirm:$False

  if (@(Get-NetRoute | ?{$_.DestinationPrefix -match '192.168.1.0/24'}).count -gt 0) {
    Remove-NetRoute -DestinationPrefix "192.168.1.0/24" -Confirm:$False
  }
  if (@(Get-NetRoute | ?{$_.DestinationPrefix -match '192.168.2.0/24'}).count -gt 0) {
    Remove-NetRoute -DestinationPrefix "192.168.2.0/24" -Confirm:$False
  }
}

#######################################################################
#
#######################################################################
function prettyprint-route {
  Get-NetRoute -AddressFamily ipv4 | ? {
    $_.ifIndex -in (
      (Get-NetIPInterface -AddressFamily ipv4 |
        ? {$_.ConnectionState -eq "Connected"} |
        select ifIndex
      ).ifIndex
    )
  } |
  select -property RouteMetric,
    ifIndex,
    DestinationPrefix,
    @{Name="mask";Expression={[int]($_.DestinationPrefix -replace '.*/(\d+)$','$1')}},
    NextHop,
    interfaceMetric |
  sort routemetric,
    ifindex,
    @{Expression="mask"; Descending=$True},
    interfaceMetric,
    DestinationPrefix |
  ft
}

#######################################################################
#
#######################################################################
function prepare-gateway {
  "`nnow, there should be some bad guys like this: "
  Get-NetRoute | ?{$_.DestinationPrefix -match '.0.0.0/1'}

  if ((Get-NetRoute | ?{$_.DestinationPrefix -match '.0.0.0/1'} | measure).count -gt 2) {
@"
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !
  ! something very bad happened, cleared all rules
  ! please reconnect all of your vpns manually
  !
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"@
    Remove-NetRoute -DestinationPrefix 0.0.0.0/1 -Confirm:$False
    Remove-NetRoute -DestinationPrefix 128.0.0.0/1 -Confirm:$False
    disconnect-all
    exit
  }


  $targetIp = (Get-NetRoute | ?{$_.DestinationPrefix -match '0.0.0.0/1'}).nexthop
  if ($targetIp -eq $null) {
    return
  }
  "`nwe got the gateway ip for stg jump server: $targetIp"
  if ($targetIp -ne (Get-NetRoute | ?{$_.DestinationPrefix -match '128.0.0.0/1'}).nexthop) {
    "`nso weird, the gateway ip was different?.."
    return
  }

  $ifIndex = (Get-NetRoute | ?{$_.DestinationPrefix -match '0.0.0.0/1'}).InterfaceIndex
  "`nnot everyone will have the same InterfaceIndex for the connection, we had: $ifIndex"

@"

  #######################################################################
  #
  # preparation done, do the staff!!
  #
  #######################################################################
"@
  clear-trash
  New-NetRoute -PolicyStore ActiveStore -DestinationPrefix "192.168.1.0/24" -NextHop $targetIp -InterfaceIndex $ifIndex
  New-NetRoute -PolicyStore ActiveStore -DestinationPrefix "192.168.2.0/24" -NextHop $targetIp -InterfaceIndex $ifIndex

  "`nok, let's have a show for our route now:"
  prettyprint-route
}

#######################################################################
#
#######################################################################
function connect-anyConnect {
@"
  #######################################################################
  #
  # finally, connect other cute vpns
  #
  #######################################################################
"@
"`nnow starting OpenVPN for ${devOvpn}:"
  # & 'C:\Program Files\OpenVPN\bin\openvpn-gui.exe' "--command", "disconnect", "arise-cdx"
  clc "${home}\OpenVPN\log\$devOvpn.log"
  & 'C:\Program Files\OpenVPN\bin\openvpn-gui.exe' "--connect", $devOvpn
  wait-pattern "${home}\OpenVPN\log\$devOvpn.log" 'Initialization Sequence Completed'

  # "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe" -s < "${home}\AppData\Local\Cisco\Cisco AnyConnect Secure Mobility Client\connect.txt"
  Start-Sleep -Seconds 2
  "`nnow starting AnyConnect:"
  cat "${home}\AppData\Local\Cisco\Cisco AnyConnect Secure Mobility Client\connect.txt" | & "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe" '-s'
}

function disconnect-anyConnect {
  & "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe" 'disconnect'
}


elevate-self -self $("-File `"" + $MyInvocation.MyCommand.path + "`" " + $MyInvocation.UnboundArguments)
main
exit



#######################################################################
# Some useful commands for debug lawson vpn
#######################################################################
function useful-commands {
  # get effective interface
  Get-NetIPInterface -AddressFamily ipv4 -ConnectionState conn| sort InterfaceMetric

  # get DnsServerAddress for interface
  Get-DnsClientServerAddress -AddressFamily ipv4 | ?{$_.InterfaceIndex -in @(12,18)} | fc
}

#######################################################################
#
#######################################################################
function fix-route {

}

#######################################################################
#
#######################################################################
function log-info {

}

#######################################################################
#
#######################################################################
function log-debug {

}

#######################################################################
#
#######################################################################
function st-stub {

}

#######################################################################
#
#######################################################################
function clear-lawson {
  Remove-NetRoute -DestinationPrefix 0.0.0.0/1 -Confirm:$False
  Remove-NetRoute -DestinationPrefix 128.0.0.0/1 -Confirm:$False

  if (@(Get-NetRoute | ?{$_.DestinationPrefix -match '10.234.0.0/16'}).count -gt 0) {
    Remove-NetRoute -DestinationPrefix "10.234.0.0/16" -Confirm:$False
  }
}


#######################################################################
# Lawson VPN
#######################################################################
function prepare-lawson {
  "`nnow, there should be some bad guys like this: "
  Get-NetRoute | ?{$_.DestinationPrefix -match '.0.0.0/1'}

  if ((Get-NetRoute | ?{$_.DestinationPrefix -match '.0.0.0/1'} | measure).count -gt 2) {
@"
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !
  ! something very bad happened, cleared all rules
  ! please reconnect all of your vpns manually
  !
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"@
    Remove-NetRoute -DestinationPrefix 0.0.0.0/1 -Confirm:$False
    Remove-NetRoute -DestinationPrefix 128.0.0.0/1 -Confirm:$False
    disconnect-all
    exit
  }


  $targetIp = (Get-NetRoute | ?{$_.DestinationPrefix -match '0.0.0.0/1'}).nexthop
  if ($targetIp -eq $null) {
    return
  }
  "`nwe got the gateway ip for stg jump server: $targetIp"
  if ($targetIp -ne (Get-NetRoute | ?{$_.DestinationPrefix -match '128.0.0.0/1'}).nexthop) {
    "`nso weird, the gateway ip was different?.."
    return
  }

  $ifIndex = (Get-NetRoute | ?{$_.DestinationPrefix -match '0.0.0.0/1'}).InterfaceIndex
  "`nnot everyone will have the same InterfaceIndex for the connection, we had: $ifIndex"

@"

  #######################################################################
  #
  # preparation done, do the staff!!
  #
  #######################################################################
"@
  clear-lawson
  New-NetRoute -PolicyStore ActiveStore -DestinationPrefix "10.234.0.0/16" -NextHop $targetIp -InterfaceIndex $ifIndex
  # New-NetRoute -PolicyStore ActiveStore -DestinationPrefix "192.168.2.0/24" -NextHop $targetIp -InterfaceIndex $ifIndex

  "`nok, let's have a show for our route now:"
  prettyprint-route
}


