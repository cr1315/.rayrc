# pnpm は PNPM_HOME で global / store / global bin を探す（install.ps1 を参照）
$__rayrc_pnpm_bin = Join-Path $__rayrc_data_dir 'bin'
if (Test-Path -LiteralPath $__rayrc_pnpm_bin) {
  $env:PNPM_HOME = $__rayrc_data_dir
  __rayrc_path_prepend $__rayrc_pnpm_bin
}
if (Get-Command pnpm -CommandType Application -ErrorAction SilentlyContinue) {
  pnpm completion pwsh 2>$null | Out-String | Invoke-Expression
}
