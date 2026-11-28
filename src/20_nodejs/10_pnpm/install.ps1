# pnpm は公式 installer で data plane に入れる（D3。bash / zsh と同じ）
#   PNPM_HOME           : pnpm 本体・global・store の置き場所（= このモジュールの data dir）
#   PNPM_NO_MODIFY_PATH : ユーザー環境変数（PATH / PNPM_HOME）とシェル設定を書き換えさせない（pnpm 12.16+）
# pnpm と `pnpm add -g` の bin は $PNPM_HOME\bin に入り、main.ps1 がそれを PATH に足す（bash / zsh と同じ）
$env:PNPM_HOME = $__rayrc_data_dir
if (-not (Test-Path -Path (Join-Path $env:PNPM_HOME 'bin\pnpm*'))) {
  if (-not (__rayrc_run_installer 'https://get.pnpm.io/install.ps1' -Environment @{ PNPM_NO_MODIFY_PATH = '1' })) {
    Write-Warning "[rayrc] failed to install pnpm"
  }
}
