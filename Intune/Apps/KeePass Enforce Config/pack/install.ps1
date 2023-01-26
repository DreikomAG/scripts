$destinationFolder = "C:\Program Files\KeePass Password Safe 2"

if (!(Test-Path -path $destinationFolder)) {New-Item $destinationFolder -Type Directory}
Copy-Item ".\KeePass.config.enforced.xml" -Destination $destinationFolder -Force