# libs/bin を PATH の先頭に足す（bash / zsh の 00_bin/main.sh と同じ。C1）
# Scoop で入れたものは Scoop の shims に任せる（D2）。libs/bin に入るのは、公式 installer と
# uv tool / pnpm で rayrc の data plane に置いたもの（uv / uvx / pipx / poetry / glances / http など）
if (-not (Test-Path -LiteralPath $__rayrc_bin_dir)) {
  New-Item -ItemType Directory -Force -Path $__rayrc_bin_dir | Out-Null
}
__rayrc_path_prepend $__rayrc_bin_dir
