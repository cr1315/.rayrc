# Node の各バージョンは libs/nodejs/fnm に置く（bash / zsh と同じ）
# --use-on-cd: .node-version / .nvmrc / package.json に合わせてディレクトリ移動時に切り替える
if (Get-Command fnm -CommandType Application -ErrorAction SilentlyContinue) {
  $env:FNM_DIR = $__rayrc_data_dir
  fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
  fnm completions --shell powershell 2>$null | Out-String | Invoke-Expression
}
