# httpie は Scoop に無いので uv tool で入れる。置き場所（UV_TOOL_DIR / UV_TOOL_BIN_DIR）は
# 20_python/01_uv が設定したものに従う（このモジュールは uv の data plane のレイアウトを知らない）。
# 02 < 20 の順で読まれるので、uv がまだ無い初回の install では飛ばす（もう一度 install すれば入る）
if (-not (Get-Command uv -CommandType Application -ErrorAction SilentlyContinue) -or -not $env:UV_TOOL_DIR) {
  Write-Warning "[rayrc] uv is not set up yet; run install again to get httpie"
  return
}
if (-not (Get-Command http -CommandType Application -ErrorAction SilentlyContinue)) {
  uv tool install --force --python 3.13 httpie *> $null
}
