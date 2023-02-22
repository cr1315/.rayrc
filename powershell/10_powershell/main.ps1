function ssh() {
  $ssh_bin = (gcm -type "Application" ssh).path

  ## shortcut
  if ($args.count -ge 2) {
    # echo "& '$ssh_bin' $args"
    Invoke-Expression "& '$ssh_bin' $args"
    return
  }

  if ($args.count -eq 1) {
    if ("$(${args}[0])" -match '^-') {
      Invoke-Expression "& '$ssh_bin' $args"
      return
    }
  }

  $host_lists = (ls "$env:USERPROFILE/.ssh" -filter "*config" -recurse | %{
    sls '^Host ' $_.fullname
  }).line -replace '^Host ', ''
  # $host_lists

  if ($args.count -eq 1) {
    $hosts_filtered = ($host_lists | sls "$(${args}[0])").line
  } else {
    $hosts_filtered = $host_lists
  }
  # $hosts_filtered

  if (($hosts_filtered).count -gt 1) {
    $result = $hosts_filtered | fzf
  } elseif (($hosts_filtered).count -eq 1) {
    $result = $hosts_filtered
  } else {
    $result = "$(${args}[0])"
  }

  echo $($result -replace '^', "& '${ssh_bin}' ")
  Invoke-Expression $($result -replace '^', "& '${ssh_bin}' ")
}
