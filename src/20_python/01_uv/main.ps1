if (Get-Command uv -CommandType Application -ErrorAction SilentlyContinue) {
  $env:UV_TOOL_DIR           = Join-Path $__rayrc_data_dir 'tools'
  $env:UV_TOOL_BIN_DIR       = $__rayrc_bin_dir
  $env:UV_PYTHON_INSTALL_DIR = Join-Path $__rayrc_data_dir 'python'
  $env:UV_MANAGED_PYTHON     = '1'

  uv generate-shell-completion powershell 2>$null | Out-String | Invoke-Expression
  uvx --generate-shell-completion powershell 2>$null | Out-String | Invoke-Expression
}
