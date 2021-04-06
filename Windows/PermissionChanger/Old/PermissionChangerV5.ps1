[CmdletBinding()]
Param(
  [Parameter(Mandatory=$false)]
   [switch]$Delete,
   [Parameter(Mandatory=$false)]
   [switch]$Y,
   [Parameter(Mandatory=$false)]
   [String]$Path = $null
)
$Version = "PermissionChangerV5"
$Date = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
Write-Host "`nStarting $Version DREIKOM AG by Raphael Büchi $Date`n" -ForegroundColor Yellow
Write-Host "This Programm will setup user-specific permission on home or profile folders`n"
if ($Y) {
    $confirmation = 'y'
}
if ($Path -eq "") {
    $Path = Read-Host "Input your path to the the user share folder"
}
if ($confirmation -ne 'y') {
    $confirmation = Read-Host "Are you shure you want to change the permissions on: $Path `n(Yes, Y to confirm or No, N to cancle)"
}
if ($confirmation -eq 'y') {
    $Date = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    "******************************************************************************************" >> "PermissionChangerLog.txt"
    "Starting $Version $Path $Date" >> "PermissionChangerLog.txt"
    "******************************************************************************************" >> "PermissionChangerLog.txt"
    Write-Host "`nChanging permissions on: $Path`n"
    $Domain = (Get-ADDomain).NetBIOSName
    $Permissions = "$Domain\domänen-admins:FullControl", "SYSTEM:FullControl"
    $AccessRules = @()
    ForEach ($Perm in $Permissions.Split(",")) {
        $Group = $Perm.Split(":")[0]
	    $Level = $Perm.Split(":")[1]
	    $AccessRules += New-Object System.Security.AccessControl.FileSystemAccessRule($Group,$Level, "ContainerInherit, ObjectInherit", "None", "Allow")
    }
    $Dirs = Get-ChildItem -Path "$Path\*" | Where { $_.PSisContainer }
    $UserError = @()
    ForEach ($Dir in $Dirs) {
        $User = Split-Path $Dir.Fullname -Leaf
        $User = ($User).Replace(".V2","")
        $User = ($User).Replace(".V3","")
        $User = ($User).Replace(".V4","")
        $User = ($User).Replace(".V5","")
        $User = ($User).Replace(".V6","")
        Try {
            $Test = Get-ADUser $User -ErrorAction Stop
	        Write-Host "$($User): $($Dir.Fullname)" -ForegroundColor Green
	        $ACL = Get-Acl $Dir -ErrorAction Stop 
            #Set inheritance to no
	        $ACL.SetAccessRuleProtection($true, $false)  
            #Set owner to domain-admins
            $ACL.SetOwner([System.Security.Principal.NTAccount]"$Domain\domänen-admins")
            #Remove old permissions
	        $ACL.Access | ForEach { [Void]$ACL.RemoveAccessRule($_) }
            #Set new permissions
	        ForEach ($Rule in $AccessRules) {
                 $ACL.AddAccessRule($Rule)
	        }
            $UserRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$Domain\$User","Modify", "ContainerInherit, ObjectInherit", "None", "Allow")
	        $ACL.AddAccessRule($UserRule)
	        Set-Acl -path $Dir -AclObject $ACL -ErrorAction Stop
        } Catch {
            $Date = Get-Date -Format "HH:mm:ss"
            Write-Host "$Date $User not found $($Dir.Fullname)" -ForegroundColor Red
            "$Date $User not found $($Dir.Fullname)" >> "PermissionChangerLog.txt"
	    }
    }
    $Date = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    Write-Host "`nPermissionChanger finished $Date`n" -ForegroundColor Yellow
    "******************************************************************************************" >> "PermissionChangerLog.txt"
    "PermissionChanger finished $Date" >> "PermissionChangerLog.txt"
 } else {
    Write-Host "`n PermissionChanger cancelled`n" -ForegroundColor Yellow
 }