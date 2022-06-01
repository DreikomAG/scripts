#The command below will get the Operating System information, convert the result to HTML code as a table and store it to a variable
$OSinfo = Get-CimInstance -Class Win32_OperatingSystem | ConvertTo-Html -Property Version,Caption,BuildNumber,Manufacturer -Fragment

#The command below will get the Processor information, convert the result to HTML code as table and store it to a variable
$ProcessInfo = Get-CimInstance -ClassName Win32_Processor | ConvertTo-Html -Property DeviceID,Name,Caption,MaxClockSpeed,SocketDesignation,Manufacturer -Fragment

#The command below will get the BIOS information, convert the result to HTML code as table and store it to a variable
$BiosInfo = Get-CimInstance -ClassName Win32_BIOS | ConvertTo-Html -Property SMBIOSBIOSVersion,Manufacturer,Name,SerialNumber -Fragment

#The command below will get the details of Disk, convert the result to HTML code as table and store it to a variable
$DiscInfo = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | ConvertTo-Html -Property DeviceID,DriveType,ProviderName,VolumeName,Size,FreeSpace -Fragment

#The command below will get first 10 services information, convert the result to HTML code as table and store it to a variable
$ServicesInfo = Get-CimInstance -ClassName Win32_Service | Select-Object -First 10  |ConvertTo-Html -Property Name,DisplayName,State -Fragment
 
#The command below will combine all the information gathered into a single HTML report
$Report = ConvertTo-HTML -Body "$ComputerName $OSinfo $ProcessInfo $BiosInfo $DiscInfo $ServicesInfo" -Title "Computer Information Report" 

#The command below will generate the report to an HTML file
$Report | Out-File .\Basic-Computer-Information-Report.html
