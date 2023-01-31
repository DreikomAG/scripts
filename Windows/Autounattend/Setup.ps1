$Version = "1.1.0"
Start-Transcript -Path "C:\Temp\Autounattend.log"
Write-Host "Version: $Version"
Set-Location D:\
Set-ExecutionPolicy Unrestricted -Scope Process
REG add "HKLM\Software\MyIntuneApps" /v "SetLanguage-de-CH" /t REG_DWORD /d 1 /f /reg:64 | Out-Null
$WlanConfig = ".\wifi.txt"
.\SetupWifi.ps1 -SSID (Get-Content $WlanConfig | Select-Object -First 1) -PSK (Get-Content $WlanConfig | Select-Object -First 1 -Skip 1)
Write-Host "Waiting 180s for stable WLAN connection"
.\TestConnection.ps1 -Script "Start-Sleep -Seconds 180" # Wait for WLAN

.\TestConnection.ps1 -Script .\Chocolatey.ps1 #Install Choco and Adobe Reader

if (.\CheckHP.ps1) { .\TestConnection.ps1 -Script .\Hpia.ps1 } #Install HPIA and update drivers
.\TestConnection.ps1 -Script .\WindowsUpdates.ps1 #Install Windows Updates and reboot
Stop-Transcript