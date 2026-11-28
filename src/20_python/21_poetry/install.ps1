if (-not (Get-Command uv -CommandType Application -ErrorAction SilentlyContinue)) { return }

if (-not (Get-Command poetry -CommandType Application -ErrorAction SilentlyContinue)) {
  uv tool install --force --python 3.13 poetry *> $null
}
