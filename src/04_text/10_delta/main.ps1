if (Get-Command delta -CommandType Application -ErrorAction SilentlyContinue) {
  $env:DELTA_FEATURES = '+side-by-side'
}
