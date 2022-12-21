$RegistryPath = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU"

If (-NOT (Test-Path $RegistryPath)) {
    New-Item -Path $RegistryPath -Force | Out-Null
}
New-ItemProperty -Path $RegistryPath -Name "NoAutoUpdate" -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path $RegistryPath -Name "AUOptions" -Value 1 -PropertyType DWORD -Force