# httpie は uv tool で入れる（3 方言とも同じ。02_pipx / 21_poetry と同じ）。
# 置き場所（UV_TOOL_DIR / UV_TOOL_BIN_DIR）は 01_uv の install.ps1 が設定したものに従う
if (-not (Get-Command uv -CommandType Application -ErrorAction SilentlyContinue) -or -not $env:UV_TOOL_DIR) { return }

## `http` ではなく uv の venv を見る（ほかの方法で入れた http があっても、uv の管理下に入れる）
if (-not (Test-Path -LiteralPath (Join-Path $env:UV_TOOL_DIR 'httpie'))) {
  uv tool install --force --python 3.13 httpie *> $null
}
