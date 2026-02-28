$serviceName = "DGService"

# 1. 権限の自己検証と昇格フェーズ
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. 処刑前のステータス確認
Write-Host "`n[Before] ターゲットの現在状態:" -ForegroundColor Cyan
Get-Service -Name $serviceName | Select-Object Name, Status, StartType | Format-Table -AutoSize

# 3. 執行フェーズ (SCMバイパスによるプロセス直接暗殺)
Write-Host "SCMをバイパスし、プロセス (PID) の直接破壊を実行中..." -ForegroundColor Yellow

# CIM/WMIを使って、サービス名から現在のPIDを逆引きする
$svc = Get-CimInstance Win32_Service -Filter "Name='$serviceName'"

if ($svc.ProcessId -gt 0) {
    # タスクマネージャーと同じカーネルレベルの強制終了 (NtTerminateProcessのラップ)
    Stop-Process -Id $svc.ProcessId -Force
    Write-Host "PID $($svc.ProcessId) のメモリ空間を強制解放しました。" -ForegroundColor Green

    # サービスが完全に落ちるまでOSのコンテキストスイッチを少し待つ
    Start-Sleep -Seconds 2
}
else {
    Write-Host "対象プロセスのPIDが検出されません。(既に停止している可能性があります)" -ForegroundColor Gray
}

# スタートアップの降格 (エラーが出ていなかったのでここは通るはずです)
Set-Service -Name $serviceName -StartupType Manual

# 4. 処刑後のステータス確認
Write-Host "`n[After] ターゲットの最終状態:" -ForegroundColor Green
Get-Service -Name $serviceName | Select-Object Name, Status, StartType | Format-Table -AutoSize

# 5. セッションの維持
Write-Host "`n完了しました。結果を確認したら、任意のキーを押してウィンドウを閉じてください..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
