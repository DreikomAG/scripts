$Version = "5.2.0"  
$Exe = "hp-hpia-$Version.exe"
$ExePath = "C:\Temp\$Exe"

$url = "https://hpia.hpcloud.hp.com/downloads/hpia/$Exe"

Invoke-WebRequest -Uri $url -OutFile $ExePath

Start-Process -Wait -FilePath "$ExePath" -ArgumentList "/s /e /f C:\Hpia" -PassThru
Start-Process -Wait -FilePath "C:\Hpia\HPImageAssistant.exe" -ArgumentList "/Operation:Analyze /Category:All /Selection:All /Action:Install /Silent /ReportFolder:C:\Hpia\HPIAReport /Softpaqdownloadfolder:C:\Hpia\HPIASoftpaqs" -PassThru