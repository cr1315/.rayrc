# 一時的な回避策（bash / zsh の main と同じ）: Claude Code の VS Code 拡張の webview の CSP に
# `font-src data:` が無く、編集ファイルの一覧のアイコンが出ない。入っている最新の拡張に 1 回だけパッチを当てる。
# 上流で直ったら消す
$__rayrc_ext = Get-ChildItem -Directory -Path (Join-Path $HOME '.vscode\extensions') -Filter 'anthropic.claude-code-*' -ErrorAction SilentlyContinue |
  Sort-Object { [version](($_.Name -replace '^anthropic\.claude-code-', '') -replace '[^0-9.].*$', '') } -ErrorAction SilentlyContinue |
  Select-Object -Last 1
if ($__rayrc_ext) {
  $__rayrc_js = Join-Path $__rayrc_ext.FullName 'extension.js'
  $__rayrc_re = 'font-src \$\{[A-Za-z_$]+\.cspSource\}'
  if (Test-Path -LiteralPath $__rayrc_js) {
    $__rayrc_src = [IO.File]::ReadAllText($__rayrc_js)
    if ($__rayrc_src -match "$__rayrc_re data:") {
      ## already patched
    }
    elseif ($__rayrc_src -notmatch $__rayrc_re) {
      Write-Host "  .rayrc: font-src not found in $__rayrc_js; CSP patch skipped (maybe no longer needed)"
    }
    else {
      Copy-Item -LiteralPath $__rayrc_js -Destination "$__rayrc_js.bak" -Force
      [IO.File]::WriteAllText($__rayrc_js, ($__rayrc_src -replace "($__rayrc_re)", '$1 data:'))
      Write-Host "  .rayrc: patched font-src CSP in $__rayrc_js (reload the VSCode window)"
    }
  }
}

if (Get-Command claude -CommandType Application -ErrorAction SilentlyContinue) {
  ## use_bedrock は install.ps1 が作る。~/.use_bedrock は手で置く上書き用
  if ((Test-Path -LiteralPath (Join-Path $__rayrc_data_dir 'use_bedrock')) -or
      (Test-Path -LiteralPath (Join-Path $HOME '.use_bedrock'))) {
    $env:CLAUDE_CODE_USE_BEDROCK = '1'
  }
}
