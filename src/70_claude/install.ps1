# Claude Code は公式 installer で入れる（D19。bash / zsh と同じ）
# ~/.claude は libs/claude/.claude への junction にし、installer より前に張る（bash / zsh と同じ順）:
#   installer のダウンロード先 ~/.claude\downloads は固定で、`claude install` も backups / sessions を書くので、
#   後から張ると、installer が作っただけの ~/.claude を退避することになる
# 既存の ~/.claude（rayrc 以外）は ~/.claude_rayrc_bkup_<timestamp> へ退避する（bash / zsh と同じ ad-hoc な退避）
__rayrc_link_dir -Link (Join-Path $HOME '.claude') -Target (Join-Path $__rayrc_data_dir '.claude')

## installer は ~\.local\bin\claude.exe に置くが、PATH には足さない。bash / zsh は libs/bin に symlink するが、
## Windows の symlink は管理者か開発者モードが要るので、~\.local\bin を PATH に足す（main.ps1 も同じ）
$__rayrc_claude_bin = Join-Path $HOME '.local\bin'
if (Test-Path -LiteralPath (Join-Path $__rayrc_claude_bin 'claude.exe')) {
  __rayrc_path_prepend $__rayrc_claude_bin
}

if (Get-Command claude -CommandType Application -ErrorAction SilentlyContinue) {
  claude update *> $null
}
elseif (__rayrc_run_installer 'https://claude.ai/install.ps1') {
  __rayrc_path_prepend $__rayrc_claude_bin
}
else {
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
