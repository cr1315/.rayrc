# httpie は Scoop に無いので uv tool で入れる（02_pipx / 21_poetry と同じ）。
# 置き場所（UV_TOOL_DIR / UV_TOOL_BIN_DIR）は 01_uv の install.ps1 が設定したものに従う
if (-not (Get-Command uv -CommandType Application -ErrorAction SilentlyContinue)) { return }

if (-not (Get-Command http -CommandType Application -ErrorAction SilentlyContinue)) {
  uv tool install --force --python 3.13 httpie *> $null
}
