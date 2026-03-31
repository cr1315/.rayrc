# Niri Silent Launcher
function Start-Niri {
    [CmdletBinding()]
    param (
        # 必要であれば、あなたの環境に合わせて変更してください
        [string]$DistroName = "archlinux"
    )

    Write-Host "Igniting Niri Wayland Compositor on $DistroName..." -ForegroundColor Cyan

    $WshShell = New-Object -ComObject WScript.Shell

    # 実行するコマンドを組み立てる
    $Command = "wsl.exe -d $DistroName -- bash -lc `"niri`""

    # WScript.Shell.Run (Command, WindowStyle, WaitOnReturn)
    #   0      : ウィンドウを完全に非表示にする（Console Flashを回避）
    #   $false : 非同期実行（Niriの終了を待たずにPowerShellのプロンプトを返す）
    $WshShell.Run($Command, 0, $false)
}
