Start-Transcript -Path "C:\Temp\Autounattend.log"
Set-ExecutionPolicy Unrestricted -Scope Process
REG add "HKLM\Software\MyIntuneApps" /v "SetLanguage-de-CH" /t REG_DWORD /d 1 /f /reg:64 | Out-Null
netsh wlan add profile filename=D:\WlanTecTest.xml user=all
D:\TestConnection.ps1 -Script "Start-Sleep -Seconds 30" # Wait for WLAN

D:\TestConnection.ps1 -Script D:\Chocolatey.ps1 #Install Choco and Adobe Reader

if (D:\CheckHP.ps1) { D:\TestConnection.ps1 -Script D:\Hpia.ps1 } #Install HPIA and update drivers
Stop-Transcript