# git の global 設定（bash / zsh の install と同じ。値が未設定のときだけ書き、手で変えた値は残して警告する）
# gitstatus のプロンプトは bash / zsh 専用（PowerShell は 22_ohmyposh が担う）なので、ここは設定だけ
# credential.helper は設定しない（D18）: Git for Windows は Git Credential Manager を system 側に設定しているので、
#   global を見ると「未設定」になり、`store`（平文保存）で上書きしてしまう
if (-not (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)) { return }

function __rayrc_git_config_ensure {
  param([string]$Key, [string]$Want)
  $current = git config --global --get $Key
  if ($LASTEXITCODE -ne 0) {
    git config --global $Key $Want
  }
  elseif ($current -ne $Want) {
    Write-Warning "[rayrc] git config $Key is '$current' (rayrc default: '$Want'), left as is"
  }
}

__rayrc_git_config_ensure alias.st status
__rayrc_git_config_ensure alias.co checkout
__rayrc_git_config_ensure alias.cm commit
__rayrc_git_config_ensure alias.b branch
__rayrc_git_config_ensure alias.lg1 "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"
__rayrc_git_config_ensure alias.lg2 "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all"
__rayrc_git_config_ensure alias.lg '!git lg1'
__rayrc_git_config_ensure pull.rebase false
__rayrc_git_config_ensure branch.autoSetupMerge simple
__rayrc_git_config_ensure push.autoSetupRemote true

Remove-Item function:__rayrc_git_config_ensure
