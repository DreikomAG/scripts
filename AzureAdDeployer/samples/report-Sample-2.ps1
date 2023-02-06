#The command below will get the name of the computer
$ComputerName = "<h1>Computer name: $env:computername</h1>"

#The command below will get the Operating System information, convert the result to HTML code as table and store it to a variable
$OSinfo = Get-CimInstance -Class Win32_OperatingSystem | ConvertTo-Html -Property Version,Caption,BuildNumber,Manufacturer -Fragment -PreContent "<h2>Operating System Information</h2>"

#The command below will get the Processor information, convert the result to HTML code as table and store it to a variable
$ProcessInfo = Get-CimInstance -ClassName Win32_Processor | ConvertTo-Html -Property DeviceID,Name,Caption,MaxClockSpeed,SocketDesignation,Manufacturer -Fragment -PreContent "<h2>Processor Information</h2>"

#The command below will get the BIOS information, convert the result to HTML code as table and store it to a variable
$BiosInfo = Get-CimInstance -ClassName Win32_BIOS | ConvertTo-Html -Property SMBIOSBIOSVersion,Manufacturer,Name,SerialNumber -Fragment -PreContent "<h2>BIOS Information</h2>"

#The command below will get the details of Disk, convert the result to HTML code as table and store it to a variable
$DiscInfo = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | ConvertTo-Html -Property DeviceID,DriveType,ProviderName,VolumeName,Size,FreeSpace -Fragment -PreContent "<h2>Disk Information</h2>"

#The command below will get first 10 services information, convert the result to HTML code as table and store it to a variable
$ServicesInfo = Get-CimInstance -ClassName Win32_Service | Select-Object -First 10  | ConvertTo-Html -Property Name,DisplayName,State -Fragment -PreContent "<h2>Services Information</h2>"

#The command below will combine all the information gathered into a single HTML report
$Report = ConvertTo-HTML -Body "$ComputerName $OSinfo $ProcessInfo $BiosInfo $DiscInfo $ServicesInfo" -Title "Computer Information Report" -PostContent "<p>Creation Date: $(Get-Date)<p>"

#The command below will generate the report to an HTML file
$Report | Out-File .\Basic-Computer-Information-Report.html
