# 1. コンソールI/Oのエンコーディング定義（グローバルスコープで一度だけ実行）
$env:LESSCHARSET = "utf-8"
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Console]::InputEncoding = [System.Text.Encoding]::UTF8

# 2. UI/UX設定
Set-PSReadlineOption -BellStyle None
$env:FZF_DEFAULT_OPTS = "--border --preview-window 'right:60%' --layout reverse --margin=1,4"

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
Set-PSReadLineKeyHandler -Chord Ctrl+r -ScriptBlock {
  $historyPath = (Get-PSReadlineOption).HistorySavePath

  # Get-Contentの重厚なオブジェクト生成を捨て、.NETの低水準I/Oで最速ロード
  $lines = [System.IO.File]::ReadAllLines($historyPath)

  # 重複を除去し、frecency（頻度＋最近度）スコアの高い順に並べる
  #   score = Σ 0.5^(何件前の実行か / 半減期)
  #   新しい実行ほど重く数えるので「最近よく使う」コマンドが上に来る
  $halfLife = 500.0
  $decay = [Math]::Pow(0.5, 1.0 / $halfLife)
  $scores = [System.Collections.Generic.Dictionary[string, double]]::new()
  $weight = 1.0
  for ($i = $lines.Length - 1; $i -ge 0; $i--) {
    $line = $lines[$i].Trim()
    if ($line.Length -gt 0) {
      $score = 0.0
      [void]$scores.TryGetValue($line, [ref]$score)
      $scores[$line] = $score + $weight
    }
    $weight *= $decay
  }
  $sorted = $scores.GetEnumerator() |
    Sort-Object -Property Value -Descending |
    ForEach-Object { $_.Key }

  # 本物のfzfバイナリに純粋な配列として流し込む
  #   --no-sort: 絞り込み中もスコア順を維持（--layout reverse なので先頭が一番上）
  $command = $sorted | fzf-real --no-sort

  # キャンセル（Esc）時のNullチェックを追加し、エラーを握り潰す
  if (-not [string]::IsNullOrWhiteSpace($command)) {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)
  }
}

######################################################################
## custom functions
######################################################################
. "$PSScriptRoot/ssh.ps1"
. "$PSScriptRoot/scp-git.ps1"
