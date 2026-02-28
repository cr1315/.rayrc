$serviceName = "DGService"

# 1. 権限の自己検証と昇格フェーズ
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # 未承認なら自身を特権プロセスとして再召喚し、現在のプロセスは終了する
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. 処刑前のステータス確認（検死前）
Write-Host "`n[Before] ターゲットの現在状態:" -ForegroundColor Cyan
Get-Service -Name $serviceName | Select-Object Name, Status, StartType | Format-Table -AutoSize

# 3. 執行フェーズ
Write-Host "強制停止および手動起動への降格を実行中..." -ForegroundColor Yellow
Stop-Service -Name $serviceName -Force
Set-Service -Name $serviceName -StartupType Manual

# 4. 処刑後のステータス確認（検死後）
Write-Host "`n[After] ターゲットの最終状態:" -ForegroundColor Green
Get-Service -Name $serviceName | Select-Object Name, Status, StartType | Format-Table -AutoSize

# 5. セッションの維持（結果を視認するための構造的担保）
Write-Host "`n完了しました。結果を確認したら、任意のキーを押してウィンドウを閉じてください..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
