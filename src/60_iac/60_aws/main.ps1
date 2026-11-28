if (Get-Command aws -CommandType Application -ErrorAction SilentlyContinue) {
  $env:AWS_REGION = 'ap-northeast-1'

  ## aws_completer（bash の `complete -C aws_completer aws` と同じもの。AWS 公式の PowerShell 用の書き方）
  if (Get-Command aws_completer -CommandType Application -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -Native -CommandName aws -ScriptBlock {
      param($wordToComplete, $commandAst, $cursorPosition)
      $env:COMP_LINE = $commandAst.ToString()
      if ($env:COMP_LINE.Length -lt $cursorPosition) { $env:COMP_LINE += ' ' }
      $env:COMP_POINT = $cursorPosition
      aws_completer | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
      }
      Remove-Item Env:\COMP_LINE, Env:\COMP_POINT
    }
  }

  . (Join-Path $__rayrc_ctl_dir 'ecs.ps1')
}
