# pipx 自身は uv tool で入れる（bash / zsh と同じ）
if (-not (Get-Command uv -CommandType Application -ErrorAction SilentlyContinue)) { return }

$env:PIPX_HOME    = Join-Path $__rayrc_data_dir 'run'
$env:PIPX_BIN_DIR = $__rayrc_bin_dir
if (-not (Get-Command pipx -CommandType Application -ErrorAction SilentlyContinue)) {
  uv tool install --force --python 3.13 pipx *> $null
}
