if (-not (Get-Command uv -CommandType Application -ErrorAction SilentlyContinue)) { return }

if (-not (Get-Command glances -CommandType Application -ErrorAction SilentlyContinue)) {
  uv tool install --force --python 3.13 "glances[cloud,containers,ip]" *> $null
}
