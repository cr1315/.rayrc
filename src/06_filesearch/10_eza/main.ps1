# ll / la / lt はこのモジュールが持つ（bash / zsh の main.sh と同じ）。eza が無ければ Get-ChildItem に落とす
# （以前は 08_shell/10_common/main.ps1 が `sal ll ls` を持っていた。06 < 08 の順で読まれるので、
#   そのままだと eza の ll を上書きしてしまう）
if (Get-Command eza -CommandType Application -ErrorAction SilentlyContinue) {
  function la { eza --icons --git --time-style long-iso -ahl @args }
  function ll { eza --icons --git --time-style long-iso -hl @args }
  function lt { eza --icons --git --time-style long-iso -hlT @args }
}
else {
  function la { Get-ChildItem -Force @args }
  Set-Alias -Name ll -Value Get-ChildItem
}
