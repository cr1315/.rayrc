# mise が書くものは、すべて libs\net\mise に置く（bash / zsh の main.sh と同じ）
if (Get-Command mise -CommandType Application -ErrorAction SilentlyContinue) {
  $env:MISE_DATA_DIR           = Join-Path $__rayrc_data_dir 'data'
  $env:MISE_CONFIG_DIR         = Join-Path $__rayrc_data_dir 'config'
  $env:MISE_GLOBAL_CONFIG_FILE = Join-Path $env:MISE_CONFIG_DIR 'config.toml'
  $env:MISE_CACHE_DIR          = Join-Path $__rayrc_data_dir 'cache'
  $env:MISE_STATE_DIR          = Join-Path $__rayrc_data_dir 'state'
}
