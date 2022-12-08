$RegistryPath = "HKLM:\Software\Policies\Microsoft\AzureADAccount"
$Name = "LoadCredKeyFromProfile"
$Value = '1'

If (-NOT (Test-Path $RegistryPath)) {
    New-Item -Path $RegistryPath -Force | Out-Null
}
New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force