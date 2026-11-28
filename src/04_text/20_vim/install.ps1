# vim は Scoop で管理する。設定は bash / zsh と同じ libs/text/vim/vimfiles を使う
#   Unix:    ~/.vim     -> vimfiles（vimfiles/vimrc が読まれる）
#   Windows: ~/vimfiles -> vimfiles（Windows の vim は ~/.vim ではなく ~/vimfiles を見る）
# ~/_vimrc と ~/.vimrc は vimfiles/vimrc より優先されるので、あれば退避する（bash の ~/.vimrc と同じ扱い）
__rayrc_scoop_install vim
if (-not (Get-Command vim -CommandType Application -ErrorAction SilentlyContinue)) { return }

$vimfiles = Join-Path $__rayrc_data_dir 'vimfiles'
foreach ($rc in '_vimrc', '.vimrc') {
  __rayrc_backup_item (Join-Path $HOME $rc)
}
__rayrc_link_dir -Link (Join-Path $HOME 'vimfiles') -Target $vimfiles

$plugVim = Join-Path $vimfiles 'autoload\plug.vim'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $plugVim) | Out-Null
## ダウンロードの一時的な失敗は __rayrc_retry でやり直す（Scoop と同じ）
if (__rayrc_retry {
    try {
      Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim' -OutFile $plugVim -ErrorAction Stop
      $true
    }
    catch { $false }
  }) {
  vim -u (Join-Path $vimfiles 'plugins.vim') +PlugInstall +qa *> $null
}
else {
  Remove-Item -LiteralPath $plugVim -ErrorAction SilentlyContinue
  Write-Warning "[rayrc] failed to download plug.vim"
}
Remove-Variable vimfiles, rc, plugVim -ErrorAction SilentlyContinue
