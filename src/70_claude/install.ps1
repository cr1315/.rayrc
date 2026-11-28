# Claude Code は公式 installer で入れる（D19。bash / zsh と同じ）
# ~/.claude は libs/claude/.claude への junction にする。bash と違い、installer の前に張る:
#   installer は ~/.claude\downloads にダウンロードするので、先に張っておけば、
#   installer が作っただけの ~/.claude を毎回退避してしまうこともない
# 既存の ~/.claude（rayrc 以外）は ~/.claude_rayrc_bkup_<timestamp> へ退避する（bash と同じ ad-hoc な退避）
__rayrc_link_dir -Link (Join-Path $HOME '.claude') -Target (Join-Path $__rayrc_data_dir '.claude')

if (Get-Command claude -CommandType Application -ErrorAction SilentlyContinue) {
  claude update *> $null
}
elseif (-not (__rayrc_run_installer 'https://claude.ai/install.ps1')) {
  Write-Warning "[rayrc] failed to install claude"
}

## Bedrock を使えるかは install の時に 1 回だけ調べる（main.ps1 は印を見るだけ。
## シェル起動のたびに調べると CloudTrail に AccessDenied が積み上がる）
$__rayrc_bedrock = Join-Path $__rayrc_data_dir 'use_bedrock'
if ((Get-Command aws -CommandType Application -ErrorAction SilentlyContinue) -and
    $(aws bedrock list-foundation-models --region ap-northeast-1 *> $null; $LASTEXITCODE -eq 0)) {
  New-Item -ItemType File -Force -Path $__rayrc_bedrock | Out-Null
}
else {
  Remove-Item -LiteralPath $__rayrc_bedrock -ErrorAction SilentlyContinue
}
