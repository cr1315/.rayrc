# 1. コンソールI/Oのエンコーディング定義（グローバルスコープで一度だけ実行）
$env:LESSCHARSET = "utf-8"
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Console]::InputEncoding = [System.Text.Encoding]::UTF8

# 2. UI/UX設定
Set-PSReadlineOption -BellStyle None
#    bash/zsh（同じフォルダの main.sh / main.zsh）と揃える。ただし --height は付けない（全画面のまま）
#    --tmux は Windows では関係ないので持ってこない
$env:FZF_DEFAULT_OPTS = "--ansi --layout reverse --border --margin=1,4 --preview-window 'right:60%' " +
  "--color=info:#afaf87,prompt:#d7005f,pointer:#af5fff " +
  "--color=marker:#87ff00,spinner:#af5fff,header:#87afaf"
#    素の fzf の一覧は fd に任せる（fd は 06_filesearch/10_fd の install.ps1 で入る。無ければ fzf の既定のまま）
if (Get-Command fd -CommandType Application -ErrorAction SilentlyContinue) {
  $env:FZF_DEFAULT_COMMAND = 'fd --type f --follow --exclude .git --exclude node_modules --exclude .venv'
}
#    FZF_CTRL_R_OPTS / FZF_CTRL_T_* / FZF_ALT_C_* は bash/zsh の統合スクリプトが読むもので、
#    fzf.exe 自身は読まない。Ctrl-R は下の自前のハンドラーにオプションを直接渡す

# 3. fzfの実体パスを解決（Scoopのshimを経由せず直接起動する）
#    既定パスを最優先し、見つからない場合のみ scoop which（重い）にフォールバック
$scoopRoot = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $HOME 'scoop' }
$fzfPath = Join-Path $scoopRoot 'apps\fzf\current\fzf.exe'

if (-not (Test-Path -LiteralPath $fzfPath -PathType Leaf)) {
  $fzfPath = $null
  if (Get-Command scoop -ErrorAction SilentlyContinue) {
    # scoop which は "~\scoop\..." 形式で返すため絶対パスに変換
    $which = scoop which fzf 2>$null 6>$null | Select-Object -First 1
    if ($which -and (Test-Path $which)) { $fzfPath = Convert-Path $which }
  }
}

if ($fzfPath) {
  Set-Alias fzf-real $fzfPath
}
else {
  # Scoop未導入・fzf未インストール時はPATH上のfzfにフォールバック
  Set-Alias fzf-real fzf
}
Remove-Variable scoopRoot, fzfPath, which -ErrorAction SilentlyContinue

# 4. 履歴検索 (Ctrl+r) の最適化
#    fzf に渡すオプションは読み込み時に決めて、GetNewClosure でハンドラーに閉じ込める
#    プレビューは bash/zsh の FZF_CTRL_R_OPTS と同じく bat（下 40%、ctrl-/ で表示を切り替え）。
#    Windows の fzf はプレビューを cmd.exe で動かし、echo {} だと引用符まで出るので、
#    項目を一時ファイルに書く {f} を bat に渡す。shfmt は sh 用なので使わない
#    bat は 04_text/10_bat の install.ps1 で入る。無ければプレビューを付けない
$fzfCtrlRArgs = @('--no-sort')
if (Get-Command bat -CommandType Application -ErrorAction SilentlyContinue) {
  $fzfCtrlRArgs += @(
    '--preview', 'bat --color=always --wrap=never --theme Dracula -p -P -l ps1 {f}',
    '--preview-window', 'down:40%:wrap', '--tabstop=1',
    '--bind', 'ctrl-/:toggle-preview'
  )
}
Set-PSReadLineKeyHandler -Chord Ctrl+r -ScriptBlock {
  $historyPath = (Get-PSReadlineOption).HistorySavePath

  # Get-Contentの重厚なオブジェクト生成を捨て、.NETの低水準I/Oで最速ロード
  $lines = [System.IO.File]::ReadAllLines($historyPath)

  # 重複を除去し、「最後に使った順」を基本に、回数の多いものを少しだけ繰り上げて並べる
  #   key = rank - boost * ln(回数)   （小さいほど上）
  #   rank: 最後に使ったのが、重複を除いて何番目に新しいか（0 = 直前）
  #   boost = 6 なら 2 回で 4 件、5 回で 10 件、10 回で 14 件、100 回で 28 件ぶん繰り上がる
  #   （例: 最後が 25 番目でも 5 回使っていれば 15 番目あたり、10 回なら 11 番目あたり）
  #   最近度が主で、回数は対数なので、古いコマンドは何回使っていても上を占めない
  $boost = 6.0
  $rank = [System.Collections.Generic.Dictionary[string, int]]::new()
  $count = [System.Collections.Generic.Dictionary[string, int]]::new()
  $order = [System.Collections.Generic.List[string]]::new()
  for ($i = $lines.Length - 1; $i -ge 0; $i--) {
    $line = $lines[$i].Trim()
    if ($line.Length -eq 0) { continue }
    if ($rank.ContainsKey($line)) {
      $count[$line]++
    }
    else {
      $rank[$line] = $order.Count
      $count[$line] = 1
      $order.Add($line)
    }
  }
  # 同じ key なら新しい方を上にするため、rank をごく小さく足して一意にする（Array.Sort は安定でない）
  $keys = [double[]]::new($order.Count)
  for ($j = 0; $j -lt $order.Count; $j++) {
    $keys[$j] = $j - $boost * [Math]::Log($count[$order[$j]]) + $j * 1e-6
  }
  $sorted = $order.ToArray()
  [Array]::Sort($keys, $sorted)

  # 本物のfzfバイナリに純粋な配列として流し込む
  #   --no-sort: 絞り込み中もスコア順を維持（--layout reverse なので先頭が一番上）
  $command = $sorted | fzf-real @fzfCtrlRArgs

  # キャンセル（Esc）時のNullチェックを追加し、エラーを握り潰す
  if (-not [string]::IsNullOrWhiteSpace($command)) {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)
  }
}.GetNewClosure()
Remove-Variable fzfCtrlRArgs

######################################################################
## custom functions
######################################################################
. "$PSScriptRoot/ssh.ps1"
