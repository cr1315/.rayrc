if (Get-Command vim -CommandType Application -ErrorAction SilentlyContinue) {
  $env:EDITOR = 'vim'
}
