param(
    [string]$package = "",
    [switch]$uninstall = $false
)

if ($uninstall) {
    C:\ProgramData\chocolatey\choco.exe uninstall $package -y
} else {
    C:\ProgramData\chocolatey\choco.exe upgrade $package -y
}