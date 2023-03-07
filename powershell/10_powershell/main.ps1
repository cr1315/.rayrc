function ssh() {
  $ssh_bin = (gcm -type "Application" ssh).path

  ## shortcut
  if ($args.count -ge 2) {
    # echo "& '$ssh_bin' $args"
    Invoke-Expression "& '$ssh_bin' $args"
    return
  }

  if ($args.count -eq 1) {
    if ("$(${args}[0])" -match '^-') {
      Invoke-Expression "& '$ssh_bin' $args"
      return
    }
  }

  $host_lists = (ls "$env:USERPROFILE/.ssh" -filter "*config" -recurse | %{
    sls '^Host ' $_.fullname
  }).line -replace '^Host ', ''
  # $host_lists

  if ($args.count -eq 1) {
    $hosts_filtered = ($host_lists | sls "$(${args}[0])").line
  } else {
    $hosts_filtered = $host_lists
  }
  # $hosts_filtered

  if (($hosts_filtered).count -gt 1) {
    $result = $hosts_filtered | fzf
  } elseif (($hosts_filtered).count -eq 1) {
    $result = $hosts_filtered
  } else {
    $result = "$(${args}[0])"
  }

  echo $($result -replace '^', "& '${ssh_bin}' ")
  Invoke-Expression $($result -replace '^', "& '${ssh_bin}' ")
}

# PowerShell Core7でもConsoleのデフォルトエンコーディングはsjisなので必要
# [System.Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding("utf-8")
# [System.Console]::InputEncoding = [System.Text.Encoding]::GetEncoding("utf-8")

# git logなどのマルチバイト文字を表示させるため (絵文字含む)
$env:LESSCHARSET = "utf-8"

# 音を消す
Set-PSReadlineOption -BellStyle None

# 履歴検索
Set-PSReadLineKeyHandler -Chord Ctrl+r -ScriptBlock {
    # いつからかawkの表示がされないようになったので、以下コマンドを実行
    # Set-Alias awk C:\Users\saido\scoop\apps\msys2\current\usr\bin\awk.exe
    ## $command = Get-Content (Get-PSReadlineOption).HistorySavePath | awk '!a[$0]++' | fzf --tac
    $command = Get-Content (Get-PSReadlineOption).HistorySavePath | fzf --tac --no-sort
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)
}