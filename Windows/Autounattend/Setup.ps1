Set-ExecutionPolicy Unrestricted -Scope Process
REG add "HKLM\Software\MyIntuneApps" /v "SetLanguage-de-CH" /t REG_DWORD /d 1 /f /reg:64 | Out-Null
netsh wlan add profile filename=D:\WlanTecTest.xml user=all

D:\TestConnection.ps1 -Script D:\Chocolatey.ps1

if (D:\CheckHP.ps1) { D:\TestConnection.ps1 -Script D:\Hpia.ps1 }