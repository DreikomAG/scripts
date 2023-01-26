msiexec /i "PrimeClient.msi" /q
Start-Sleep -Seconds 10
Copy-Item "Portals.xml" -Destination "C:\WinOfficePrime"