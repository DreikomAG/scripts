$shortcuts = Get-ChildItem -Path "C:\Users\Public\Desktop\*" -Include "*.lnk"
foreach ($shortcut in $shortcuts)
{
    if ((Get-Acl $shortcut | Select-Object Owner).Owner -like "*\SYSTEM") {
        Write-Host "Deleting:"  $shortcut
        Remove-Item -Path $shortcut
    }
}