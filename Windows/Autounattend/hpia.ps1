$Version = "5.1.7"
$Exe = "hp-hpia-$Version.exe"
$ExePath "C:\Windows\Temp\$Exe"

Invoke-WebRequest -Uri "https://hpia.hpcloud.hp.com/downloads/hpia/$Exe" -OutFile $ExePath

$ExePath /s /e /f c:\hpia

Powershell.exe -ExecutionPolicy Bypass -Command "C:\HPIA\HPImageAssistant.exe /Operation:Analyze /Category:All /Selection:All /Action:Install /Silent /ReportFolder:C:\HPIA\HPIAReport /Softpaqdownloadfolder:C:\HPIA\HPIASoftpaqs"