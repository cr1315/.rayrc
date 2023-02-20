
function ssh() {
  $ssh_bin = (gcm ssh).path
  # $args.count
  if ($args.count -ge 2) {
    $ssh_bin $args
  }

  $result = $(ls "$env:USERPROFILE/.ssh" -filter "*config" -recurse | %{
    sls '^Host' $_.fullname | %{
      $_.line -replace '^Host ','ssh '
    }
  } | fzf)
  Invoke-Expression $($result -replace '^ssh', "${ssh_bin}")
}
