$users = "AzureAD\admin@<domain>.onmicrosoft.com", "AzAdministrator"
$group = "FSLogix Profile Exclude List"
Add-LocalGroupMember -Group $group -Member $users -ErrorAction SilentlyContinue
