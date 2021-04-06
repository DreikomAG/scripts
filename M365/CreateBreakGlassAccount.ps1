### Developed by Raphael Büchi Dreikom AG ###
### Version 1.3 ###

Connect-MsolService
if (Get-MsolUser | Where-Object { $_.DisplayName -Like "BreakGlass*" }) {
    Write-Output "Break Glass account already created. Please verify manually!"
}
else {
    Add-Type -AssemblyName System.Web

    $MsDomain = (Get-MsolDomain | Where-Object { $_.name -like "*.onmicrosoft.com" } | Where-Object { $_.name -notlike "*.mail.onmicrosoft.com" }).name
        $name = -join ((97..122) | Get-Random -Count 64 | % { [char]$_ })
        $pass = [System.Web.Security.Membership]::GeneratePassword(64, 4)
        $UPN = "$name@$MsDomain"
        Write-Output "Creation of account:"
        Write-Output $UPN
        $DisplayName = "BreakGlass $name"
        Write-Output "Password:"
        Write-Output $pass
        New-MsolUser -UserPrincipalName $UPN -DisplayName $DisplayName -ForceChangePassword $false -StrongPasswordRequired $true -Password $pass -PasswordNeverExpires $true
        Add-MsolRoleMember -RoleMemberEmailAddress $UPN -RoleName "Company Administrator"
        pause
}