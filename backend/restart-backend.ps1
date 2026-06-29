# Dung backend cu tren port 3000 roi chay lai (co FCM push)
$conn = Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if ($conn) {
  Write-Host "Dang dung process PID $($conn.OwningProcess) tren port 3000..."
  Stop-Process -Id $conn.OwningProcess -Force
  Start-Sleep -Seconds 1
}
Set-Location $PSScriptRoot
$adb = Join-Path $env:LOCALAPPDATA "Android\sdk\platform-tools\adb.exe"
if (Test-Path $adb) {
  & $adb reverse tcp:3000 tcp:3000 2>$null
}
npm start
