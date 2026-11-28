# bash / zsh の main.sh と同じ設定ファイルを使う
# （MANPAGER と `alias bat="bat --color always"` は持ってこない: PowerShell に man は無く、
#   常に色を付けるとパイプ先にエスケープシーケンスが混ざる）
if (Get-Command bat -CommandType Application -ErrorAction SilentlyContinue) {
  $env:BAT_CONFIG_PATH = Join-Path $__rayrc_data_dir 'config\bat.conf'
}
