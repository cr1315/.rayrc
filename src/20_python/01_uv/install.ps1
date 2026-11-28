# uv は公式 installer で libs/bin に入れる（D3。bash / zsh と同じ）
#   UV_INSTALL_DIR    : uv.exe / uvx.exe を libs/bin に平らに置く（uv self update は使えるまま）
#   UV_NO_MODIFY_PATH : ユーザー環境変数の PATH を書き換えさせない（PATH は 00_bin/main.ps1 が持つ）
# tool の venv と Python は data plane に置く。後続の 02_pipx などもこの env を使うので、install の間は残す
# UV_MANAGED_PYTHON: Python は uv が管理するものだけを使う。venv は元の Python を指すだけなので、
#   システムの Python に乗ると、その Python のアンインストールや更新で壊れる
$env:UV_TOOL_DIR           = Join-Path $__rayrc_data_dir 'tools'
$env:UV_TOOL_BIN_DIR       = $__rayrc_bin_dir
$env:UV_PYTHON_INSTALL_DIR = Join-Path $__rayrc_data_dir 'python'
$env:UV_MANAGED_PYTHON     = '1'

if (-not (Test-Path -LiteralPath (Join-Path $__rayrc_bin_dir 'uv.exe'))) {
  if (-not (__rayrc_run_installer 'https://astral.sh/uv/install.ps1' -Environment @{
        UV_INSTALL_DIR = $__rayrc_bin_dir; UV_NO_MODIFY_PATH = '1' })) {
    Write-Warning "[rayrc] failed to install uv"
  }
}
__rayrc_path_prepend $__rayrc_bin_dir
