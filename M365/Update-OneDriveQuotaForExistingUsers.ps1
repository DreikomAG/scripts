### Developed by Raphael Büchi Dreikom AG ###
### Version 1.0 ###

$TenantUrl = Read-Host "Enter the SharePoint admin center URL" 
Connect-SPOService -Url $TenantUrl 

$OneDriveSite = Read-Host "Enter the OneDrive Site URL" 
$OneDriveStorageQuota = Read-Host "Enter the OneDrive Storage Quota in MB" 
$OneDriveStorageQuotaWarningLevel = Read-Host "Enter the OneDrive Storage Quota Warning Level in MB" 

$sites = Get-SPOSite -IncludePersonalSite $true -Limit all -Filter "Url -like '-my.sharepoint.com/personal/'" | Select -ExpandProperty Url

foreach ($OneDriveSite in $sites) {
    write-host $OneDriveSite
    Set-SPOSite -Identity $OneDriveSite -StorageQuota $OneDriveStorageQuota -StorageQuotaWarningLevel $OneDriveStorageQuotaWarningLevel 
}
