
function sshs() {
  $result = $(ls "$env:USERPROFILE/.ssh" -filter "*config" -recurse | %{sls '^Host' $_.fullname | %{$_.line -replace '^Host ','ssh '}} | fzf)
  Invoke-Expression $result
}
