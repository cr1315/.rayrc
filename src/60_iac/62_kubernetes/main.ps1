# k.conf（bash / zsh）は移植していない: 中で呼ぶ aws.iac がどの方言でも読み込まれていないため
if (Get-Command kubectl -CommandType Application -ErrorAction SilentlyContinue) {
  Set-Alias -Name k -Value kubectl

  ## kubectl の PowerShell 用 completion は $__kubectlCompleterBlock を定義し、kubectl に登録する。
  ## alias の k にも同じものを登録する（bash の `complete -F __start_kubectl k` と同じ）
  kubectl completion powershell 2>$null | Out-String | Invoke-Expression
  if (Get-Variable __kubectlCompleterBlock -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -CommandName k -ScriptBlock $__kubectlCompleterBlock
  }
}
