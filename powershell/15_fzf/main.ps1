# 1. コンソールI/Oのエンコーディング定義（グローバルスコープで一度だけ実行）
$env:LESSCHARSET = "utf-8"
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Console]::InputEncoding = [System.Text.Encoding]::UTF8

# 2. UI/UX設定
Set-PSReadlineOption -BellStyle None
$env:FZF_DEFAULT_OPTS = "--border --preview-window 'right:60%' --layout reverse --margin=1,4"

# 3. fzfのシム問題回避（Scoopに移行するまでの暫定的なバイパス）
Set-Alias fzf-real "C:\ProgramData\chocolatey\lib\fzf\tools\fzf.exe"

# 4. 履歴検索 (Ctrl+r) の最適化
Set-PSReadLineKeyHandler -Chord Ctrl+r -ScriptBlock {
  $historyPath = (Get-PSReadlineOption).HistorySavePath

  # Get-Contentの重厚なオブジェクト生成を捨て、.NETの低水準I/Oで最速ロード
  $lines = [System.IO.File]::ReadAllLines($historyPath)

  # 本物のfzfバイナリに純粋な配列として流し込む
  $command = $lines | fzf-real --tac --no-sort

  # キャンセル（Esc）時のNullチェックを追加し、エラーを握り潰す
  if (-not [string]::IsNullOrWhiteSpace($command)) {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)
  }
}

######################################################################
## custom functions
######################################################################
. "$PSScriptRoot/ssh.ps1"
