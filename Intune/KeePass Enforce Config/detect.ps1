$expected_hash = "5F90D66A602CEE91C46AB7D7E1842197FAA58B5441F75D10503EB7CE006AFABD" #Needs to be updated after every change to the config file

$Config_File = "C:\Program Files\KeePass Password Safe 2\KeePass.config.enforced.xml"
if (Test-Path -Path $Config_File) {
    $actual_hash = (Get-FileHash -Path $Config_File).Hash
    if ($expected_hash -eq $actual_hash) {
        Write-Host "Found it!"
        Exit 0
    }
}