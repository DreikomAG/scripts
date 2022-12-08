$VhdLocations = "\\pstafslogix02.file.core.windows.net\profileshare01"
$RegistryPath = "HKLM:\Software\FSLogix\Profiles"

If (-NOT (Test-Path $RegistryPath)) {
    New-Item -Path $RegistryPath -Force | Out-Null
}
New-ItemProperty -Path $RegistryPath -Name "Enabled" -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path $RegistryPath -Name "ClearCacheOnLogoff" -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path $RegistryPath -Name "DeleteLocalProfileWhenVHDShouldApply" -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path $RegistryPath -Name "PreventLoginWithFailure" -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path $RegistryPath -Name "PreventLoginWithTempProfile" -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path $RegistryPath -Name VHDLocations -Value $VhdLocations -PropertyType STRING -Force