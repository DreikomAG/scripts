REG add "HKLM\Software\MyIntuneApps" /v "SetLanguage-de-CH" /t REG_DWORD /d 1 /f /reg:64 | Out-Null
netsh wlan add profile filename=D:\WlanTecTest.xml user=all

.\TestConnection.ps1 -Script .\Chocolatey.ps1

if (.\CheckHP.ps1) { .\TestConnection.ps1 -Script .\hpia.ps1 }