
# git logなどのマルチバイト文字を表示させるため (絵文字含む)
$env:LESSCHARSET = "utf-8"

# 音を消す
Set-PSReadlineOption -BellStyle None

##
$env:FZF_DEFAULT_OPTS="--border --preview-window 'right:60%' --layout reverse --margin=1,4"


# 履歴検索
Set-PSReadLineKeyHandler -Chord Ctrl+r -ScriptBlock {
  [System.Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding("utf-8")
  [System.Console]::InputEncoding = [System.Text.Encoding]::GetEncoding("utf-8")

  # いつからかawkの表示がされないようになったので、以下コマンドを実行
  # Set-Alias awk C:\Users\saido\scoop\apps\msys2\current\usr\bin\awk.exe
  ## $command = Get-Content (Get-PSReadlineOption).HistorySavePath | awk '!a[$0]++' | fzf --tac
  $command = Get-Content (Get-PSReadlineOption).HistorySavePath | fzf --tac --no-sort
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)
}
