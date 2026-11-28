if (Get-Command terraform -CommandType Application -ErrorAction SilentlyContinue) {
  Set-Alias -Name tf -Value terraform

  $env:TF_CLI_CONFIG_FILE  = Join-Path $__rayrc_data_dir '.terraformrc'
  $env:TF_PLUGIN_CACHE_DIR = Join-Path $HOME '.terraform.d\plugin-cache'
  if (-not (Test-Path -LiteralPath $env:TF_PLUGIN_CACHE_DIR)) {
    New-Item -ItemType Directory -Force -Path $env:TF_PLUGIN_CACHE_DIR | Out-Null
  }
}
