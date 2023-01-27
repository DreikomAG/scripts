$Version = "5.1.7"
$Exe = "hp-hpia-$Version.exe"
$ExePath = "C:\Windows\Temp\$Exe"

Invoke-WebRequest -Uri "https://hpia.hpcloud.hp.com/downloads/hpia/$Exe" -OutFile $ExePath

Start-Process -wait "$ExePath /s /e /f C:\Hpia"

Start-Process -wait "C:\Hpia\HPImageAssistant.exe /Operation:Analyze /Category:All /Selection:All /Action:Install /Silent /ReportFolder:C:\Hpia\HPIAReport /Softpaqdownloadfolder:C:\Hpia\HPIASoftpaqs"