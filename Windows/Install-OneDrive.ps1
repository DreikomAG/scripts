### Developed by Raphael Büchi Dreikom AG ###
### Version 1.0 ###

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string]$OneDriveSetupPath
)
 
$user = $env:USERNAME
$OneDrivePath = "C:\Users\$user\AppData\Local\Microsoft\OneDrive\OneDrive.exe"

$testPath = Test-Path $OneDrivePath
 
if (!$testPath) {
    $arguments = "/Silent"
    Start-Process -FilePath "$OneDriveSetupPath" -ArgumentList $arguments -Wait -PassThru -NoNewWindow
    Start-Process -FilePath $OneDrivePath
}