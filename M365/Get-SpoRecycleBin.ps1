#Config Variables
$SiteURL = "https://dreikom.sharepoint.com/sites/DreikomOrgwide"
 
#Connect to PnP Online
Connect-PnPOnline -Url $SiteURL -UseWebLogin
 
#Get Recycle bin Items
Get-PnPRecycleBinItem | Select Title, ItemType, Size, ItemState, DirName, DeletedByName, DeletedDate | Format-table -AutoSize


#Export CSV
# Get-PnPRecycleBinItem | Select Title, ItemType, Size, ItemState, DirName, DeletedByName, DeletedDate | Export-Csv "C:\Temp\RecycleBin.csv" -NoTypeInformation