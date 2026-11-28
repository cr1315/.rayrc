if (Get-Command http -CommandType Application -ErrorAction SilentlyContinue) {
  $env:HTTPIE_CONFIG_DIR = Join-Path $__rayrc_data_dir 'config'
}
