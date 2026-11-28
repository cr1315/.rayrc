# bash / zsh と同じ設定とチートシートを使う
if (Get-Command navi -CommandType Application -ErrorAction SilentlyContinue) {
  $env:NAVI_CONFIG = Join-Path $__rayrc_data_dir 'config\config.yaml'
  $env:NAVI_PATH   = Join-Path $__rayrc_data_dir 'cheats'
}
