[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false)]
    [switch]$Delete,
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    [Parameter(Mandatory = $false)]
    [switch]$Y,
    [Parameter(Mandatory = $false)]
    [string[]]$Paths = $null
)
$Version = "PermissionChangerV6"
Write-Host "`nStarting $Version DREIKOM AG by Raphael Büchi " (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")"`n" -ForegroundColor Yellow
Write-Host "This Programm will setup user-specific permission on home or profile folders`n"
if ($Y) {
    $confirmation = $true
}
if ($null -eq $Paths) {
    $Paths = Read-Host "Input your path to the the user share folder"
    $Paths = ($Paths).Replace(" ", "")
    $Paths = $Paths.Split(",")
}

foreach ($Path in $Paths) {
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "`nCould not find $Path`n" -ForegroundColor Yellow
        Write-Host "PermissionChanger cancelled`n" -ForegroundColor Yellow
        exit
        }
    }

if (!$confirmation) {
    $confirm = Read-Host "Are you shure you want to change the permissions on: $Paths `n(Yes, Y to confirm or No, N to cancle)"
    if ($confirm -eq "y") {
        $confirmation = $true
    }
}
if ($confirmation) {
    foreach ($Path in $Paths) {
        "******************************************************************************************" >> "PermissionChangerLog.txt"
        "Starting $Version $Path " + (Get-Date).ToString("dd/MM/yyyy HH:mm:ss") >> "PermissionChangerLog.txt"
        "******************************************************************************************" >> "PermissionChangerLog.txt"
        Write-Host "`nChanging permissions on: $Path`n"

            $Domain = (Get-ADDomain).NetBIOSName
            $Permissions = "VORDEFINIERT\Administratoren:FullControl", "SYSTEM:FullControl"
            $AccessRules = @()
            ForEach ($Perm in $Permissions.Split(",")) {
                $Group = $Perm.Split(":")[0]
                $Level = $Perm.Split(":")[1]
                $AccessRules += New-Object System.Security.AccessControl.FileSystemAccessRule($Group, $Level, "ContainerInherit, ObjectInherit", "None", "Allow")
            }
            $Dirs = Get-ChildItem -Path "$Path\*" | Where { $_.PSisContainer }
            $UserError = @()
            ForEach ($Dir in $Dirs) {
                $User = Split-Path $Dir.Fullname -Leaf
                $User = ($User).Replace(".V2", "")
                $User = ($User).Replace(".V3", "")
                $User = ($User).Replace(".V4", "")
                $User = ($User).Replace(".V5", "")
                $User = ($User).Replace(".V6", "")
                
                    $Test = Get-ADUser $User -ErrorAction Stop
                    Write-Host "$($User): $($Dir.Fullname)" -ForegroundColor Green
                    $ACL = Get-Acl $Dir -ErrorAction Stop 
                    #Set inheritance to no
                    $ACL.SetAccessRuleProtection($true, $false)  
                    #Set owner to domain-admins
                    $ACL.SetOwner([System.Security.Principal.NTAccount]"VORDEFINIERT\Administratoren")
                    #Remove old permissions
                    $ACL.Access | ForEach { [Void]$ACL.RemoveAccessRule($_) }
                    #Set new permissions
                    ForEach ($Rule in $AccessRules) {
                        $ACL.AddAccessRule($Rule)
                    }
                    $UserRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$Domain\$User", "Modify", "ContainerInherit, ObjectInherit", "None", "Allow")
                    $ACL.AddAccessRule($UserRule)
                    Set-Acl -path $Dir -AclObject $ACL -ErrorAction Stop

            }
            Write-Host "`nPermissionChanger finished "(Get-Date).ToString("dd/MM/yyyy HH:mm:ss") "`n" -ForegroundColor Yellow
            "******************************************************************************************" >> "PermissionChangerLog.txt"
            "PermissionChanger finished " + (Get-Date).ToString("dd/MM/yyyy HH:mm:ss") >> "PermissionChangerLog.txt"
    }
}
else {
    Write-Host "`n PermissionChanger cancelled`n" -ForegroundColor Yellow
}