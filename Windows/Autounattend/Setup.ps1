REG add "HKLM\Software\MyIntuneApps" /v "SetLanguage-de-CH" /t REG_DWORD /d 1 /f /reg:64 | Out-Null

netsh wlan add profile filename=D:\WlanTecTest.xml user=all

D:\hpia.exe /s /e /f c:\hpia


while (-not $completed) {
if (((Test-NetConnection www.google.com -Port 80 -InformationLevel "Detailed").TcpTestSucceeded) -eq $true) {       
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    $completed = $true         
} else {
Start-Sleep '5'
}
    }

C:\ProgramData\chocolatey\choco.exe install adobereader -y

choco upgrade all

Powershell.exe -ExecutionPolicy Bypass -Command "C:\HPIA\HPImageAssistant.exe /Operation:Analyze /Category:All /Selection:All /Action:Install /Silent /ReportFolder:C:\HPIA\HPIAReport /Softpaqdownloadfolder:C:\HPIA\HPIASoftpaqs"

