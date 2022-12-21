$telnet = Get-WindowsOptionalFeature -Online -FeatureName TelnetClient

if ($telnet.state -eq "Enabled") {
    Write-Host "App Detected"
    Exit 0
}