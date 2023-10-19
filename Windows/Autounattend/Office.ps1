$url = "https://c2rsetup.officeapps.live.com/c2r/download.aspx?productReleaseID=O365ProPlusRetail&platform=X64&language=de-de&TaxRegion=db&correlationId=05129f41-84d3-4c97-be58-88ee6a890820&token=06d4aa09-17a6-4d55-b66e-e1cafa044ca9&version=O16GA&source=O15OLSO365&Br=2"
$downloadPath = "C:\Temp\officesetup.exe"
$configPath = ".\OfficeConfiguration.xml"

# Download officesetup.exe
Invoke-WebRequest -Uri $url -OutFile $downloadPath

# Start officesetup.exe with administrator privileges
Start-Process -FilePath $downloadPath -ArgumentList "/configure $configPath" -Verb RunAs