
function ssh() {
  $ssh_bin = (gcm -type "Application" ssh).path
  # $args.count
  if ($args.count -ge 2) {
    & "$ssh_bin" $args
  }

  $result = $(ls "$env:USERPROFILE/.ssh" -filter "*config" -recurse | %{
    sls '^Host' $_.fullname | %{
      $_.line -replace '^Host ','ssh '
    }
  } | fzf)
  echo $($result -replace '^ssh', "& '${ssh_bin}'")
  Invoke-Expression $($result -replace '^ssh', "& '${ssh_bin}'")
}
