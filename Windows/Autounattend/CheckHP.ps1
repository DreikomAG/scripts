$manufacturer = (Get-WmiObject -Class Win32_ComputerSystem).Manufacturer
if ($manufacturer -eq "HP") {
    return $true
} else {
    return $false
}