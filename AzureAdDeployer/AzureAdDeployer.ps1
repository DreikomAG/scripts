# Maintainer: https://github.com/swissbuechi
# Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Users, Microsoft.Graph.Identity.DirectoryManagement, Microsoft.Graph.DeviceManagement.Enrolment, Microsoft.Graph.Identity.SignIns, Microsoft.Graph.Devices.CorporateManagement, ExchangeOnlineManagement, PnP.PowerShell
[CmdletBinding()]
Param(
    [switch]$UseExistingExoSession,   
    [switch]$KeepExoSessionAlive,    
    [switch]$UseExistingGraphSession,
    [switch]$KeepGraphSessionAlive,  
    [switch]$UseExistingSpoSession,
    [switch]$KeepSpoSessionAlive,
    [switch]$AddExchangeOnlineReport,
    [switch]$AddSharePointOnlineReport,
    [switch]$CreateBreakGlassAccount,
    [switch]$EnableSecurityDefaults,
    [switch]$DisableSecurityDefaults,
    [switch]$DisableEnterpiseApplicationUserConsent,
    [switch]$SetMailboxLanguage,
    [switch]$DisableSharedMailboxLogin,
    [switch]$EnableSharedMailboxCopyToSent,
    [switch]$HideUnifiedMailboxFromOutlookClient,
    [switch]$DisableAddToOneDrive
)
$ReportTitle = "Microsoft 365 Security Report"
$Version = "2.1.0"

$ReportImageUrl = "https://cdn-icons-png.flaticon.com/512/3540/3540926.png"
$LogoImageUrl = "https://dreikom.ch/typo3conf/ext/eag_website/Resources/Public/Images/dreikom_logo.svg"

$script:ExoConnected = $false
$script:GraphConnected = $false
$script:SpoConnected = $false

$script:InteractiveMode = $false
$script:MailboxLanguageCode = "de-CH"
$script:MailboxTimeZone = "W. Europe Standard Time" 

$script:CustomerName = ""

$script:CreateBreakGlassAccount = $CreateBreakGlassAccount
$script:EnableSecurityDefaults = $EnableSecurityDefaults
$script:DisableSecurityDefaults = $DisableSecurityDefaults
$script:DisableEnterpiseApplicationUserConsent = $DisableEnterpiseApplicationUserConsent
$script:SetMailboxLanguage = $SetMailboxLanguage
$script:DisableSharedMailboxLogin = $DisableSharedMailboxLogin
$script:EnableSharedMailboxCopyToSent = $EnableSharedMailboxCopyToSent
$script:HideUnifiedMailboxFromOutlookClient = $HideUnifiedMailboxFromOutlookClient
$script:DisableAddToOneDrive = $DisableAddToOneDrive

$script:AddExchangeOnlineReport = $AddExchangeOnlineReport
$script:AddSharePointOnlineReport = $AddSharePointOnlineReport

Write-Host "AzureAdDeployer version" $Version

<# Interactive inputs section #>
function CheckInteractiveMode {
    Param(
        $Parameters
    )
    if ($Parameters.Count) {
        return
    }
    $script:InteractiveMode = $true
}
function InteractiveMenu {
    $StartOptionValue = 0
    $script:AddExchangeOnlineReport = $true
    $script:AddSharePointOnlineReport = $true
    while ($result -ne $StartOptionValue) {
        $Title = ""
        $Message = ""
        $Status = @"

Report options:
E: Add Exchange Online report: $($script:AddExchangeOnlineReport)
P: Add SharePoint Online report: $($script:AddSharePointOnlineReport)

Configuration options:
1: Create BreakGlass account: $($script:CreateBreakGlassAccount)
2: Enable Security Defaults: $($script:EnableSecurityDefaults)
3: Disable Security Defaults: $($script:DisableSecurityDefaults)
4: Disable Enterprise Application user consent: $($script:DisableEnterpiseApplicationUserConsent)
5: Set mailbox language: $($script:SetMailboxLanguage)
6: Disable shared mailbox login: $($script:DisableSharedMailboxLogin)
7: Enable shared mailbox copy to sent: $($script:EnableSharedMailboxCopyToSent)
8: Hide unified mailbox from outlook client: $($script:HideUnifiedMailboxFromOutlookClient)
9: Disable add to OneDrive: $($script:DisableAddToOneDrive)

S: Start
"@
        $StartOption = New-Object System.Management.Automation.Host.ChoiceDescription "&START", "Start"
        $AddExchangeOnlineReportOption = New-Object System.Management.Automation.Host.ChoiceDescription "&EXO", "Add Exchange Online report"
        $AddSharePointOnlineReportOption = New-Object System.Management.Automation.Host.ChoiceDescription "S&PO", "Add SharePoint Online report"

        $CreateBreakGlassAccountOption = New-Object System.Management.Automation.Host.ChoiceDescription "&1", "Create BreakGlass account"
        $EnableSecurityDefaultsOption = New-Object System.Management.Automation.Host.ChoiceDescription "&2", "Enable Security Defaults"
        $DisableSecurityDefaultsOption = New-Object System.Management.Automation.Host.ChoiceDescription "&3", "Disable Security Defaults"
        $DisableEnterpiseApplicationUserConsentOption = New-Object System.Management.Automation.Host.ChoiceDescription "&4", "Disable Enterprise Application user consent"
        $SetMailboxLanguageOption = New-Object System.Management.Automation.Host.ChoiceDescription "&5", "Set mailbox language"
        $DisableSharedMailboxLoginOption = New-Object System.Management.Automation.Host.ChoiceDescription "&6", "Disable shared mailbox login"
        $EnableSharedMailboxCopyToSentOption = New-Object System.Management.Automation.Host.ChoiceDescription "&7", "Enable shared mailbox copy to sent"
        $HideUnifiedMailboxFromOutlookClientOption = New-Object System.Management.Automation.Host.ChoiceDescription "&8", "Hide unified mailbox from outlook client"
        $DisableAddToOneDriveOption = New-Object System.Management.Automation.Host.ChoiceDescription "&9", "Disable add to OneDrive"

        $Options = [System.Management.Automation.Host.ChoiceDescription[]]($StartOption, $AddExchangeOnlineReportOption, $AddSharePointOnlineReportOption, $CreateBreakGlassAccountOption, $EnableSecurityDefaultsOption, $DisableSecurityDefaultsOption, $DisableEnterpiseApplicationUserConsentOption, $SetMailboxLanguageOption, $DisableSharedMailboxLoginOption, $EnableSharedMailboxCopyToSentOption, $HideUnifiedMailboxFromOutlookClientOption, $DisableAddToOneDriveOption)
        Write-Host $Status
        $result = $host.ui.PromptForChoice($Title, $Message, $Options, $StartOptionValue)
        switch ($result) {
            0 { "Starting AzureAdDeployer" }
            1 { $script:AddExchangeOnlineReport = ! $script:AddExchangeOnlineReport }
            2 { $script:AddSharePointOnlineReport = ! $script:AddSharePointOnlineReport }
            3 { $script:CreateBreakGlassAccount = ! $script:CreateBreakGlassAccount }
            4 { $script:EnableSecurityDefaults = ! $script:EnableSecurityDefaults }
            5 { $script:DisableSecurityDefaults = ! $script:DisableSecurityDefaults }
            6 { $script:DisableEnterpiseApplicationUserConsent = ! $script:DisableEnterpiseApplicationUserConsent }
            7 { $script:SetMailboxLanguage = ! $script:SetMailboxLanguage }
            8 { $script:DisableSharedMailboxLogin = ! $script:DisableSharedMailboxLogin }
            9 { $script:EnableSharedMailboxCopyToSent = ! $script:EnableSharedMailboxCopyToSent }
            10 { $script:HideUnifiedMailboxFromOutlookClient = ! $script:HideUnifiedMailboxFromOutlookClient }
            11 { $script:DisableAddToOneDrive = ! $script:DisableAddToOneDrive }
        }
    }
}
   
<# Connect sessions section #>
function connectGraph {
    if ($UseExistingGraphSession) { return }
    if (-not $script:GraphConnected) {
        Write-Host "Connecting Graph PowerShell"
        Connect-MgGraph -Scopes "Policy.Read.All, Policy.ReadWrite.ConditionalAccess, Application.Read.All,
User.Read.All, User.ReadWrite.All, Domain.Read.All, Directory.Read.All, Directory.ReadWrite.All,
RoleManagement.ReadWrite.Directory, DeviceManagementApps.Read.All, DeviceManagementApps.ReadWrite.All,
Policy.ReadWrite.Authorization, Sites.Read.All"
    }
    if ((Get-MgContext) -ne "") {
        Write-Host "Connected to Microsoft Graph PowerShell using $((Get-MgContext).Account) account"
        $script:GraphConnected = $true
    }
}
function connectExo {
    if ($UseExistingExoSession) { return }
    if (-not $script:ExoConnected) {
        Write-Host "Connecting Exchange Online PowerShell"
        Connect-ExchangeOnline -ShowBanner:$false
    }
    if ((Get-ConnectionInformation).State -eq "Connected") {
        "Write-Host Connected to Exchange Online PowerShell using $((Get-ConnectionInformation).UserPrincipalName) account"
        $script:ExoConnected = $true
    }
}
function connectSpo {
    if ($UseExistingSpoSession) { return }
    if (-not $script:SpoConnected) {
        Write-Host "Connecting SharePoint Online PowerShell"
        if ($PSVersionTable.PSEdition -eq "Core") { Connect-PnPOnline -Url (getSpoAdminUrl) -Interactive -LaunchBrowser }
        if ($PSVersionTable.PSEdition -eq "Desktop") { Connect-PnPOnline -Url (getSpoAdminUrl) -Interactive }
    }
    if ((Get-PnPConnection) -ne "") {
        Write-Host "Connected to SharePoint Online PowerShell tenant $((Get-PnPConnection).Url)"
        $script:SpoConnected = $true
    }
}
function getSpoAdminUrl {
    return ((Invoke-MgGraphRequest -Method GET -Uri https://graph.microsoft.com/v1.0/sites/root).siteCollection.hostname) -replace ".sharepoint.com", "-admin.sharepoint.com"
}

<# Disconect session section #>
function disconnectExo {
    if ($UseExistingExoSession) { return }
    if ($script:ExoConnected) {
        Write-Host "Disconnecting Exchange Online PowerShell session"
        Disconnect-ExchangeOnline -Confirm:$false
    }
    $script:ExoConnected = $false
}
function disconnectGraph {
    if ($UseExistingGraphSession) { return }
    if ($script:GraphConnected) {
        Write-Host "Disconnecting Graph API session"
        Disconnect-Graph | Out-Null
    }
    $script:GraphConnected = $false
}
function disconnectSpo {
    if ($UseExistingSpoSession) { return }
    if ($script:SpoConnected) {
        Write-Host "Disconnecting SharePoint Online session"
        Disconnect-PnPOnline
    }
    $script:SpoConnected = $false
}

<# Customer infos#>
function organizationReport {
    $Organization = Get-MgOrganization -Property DisplayName, Id
    $script:CustomerName = $Organization.DisplayName
    return  "<h2>$($Organization.DisplayName) ($($Organization.Id))</h2>"
}

<# User Account section #>
function disableUserAccount {
    param (
        $Users
    )
    $params = @{
        AccountEnabled = "false"
    }
    Write-Host "Disable user accounts"
    foreach ($User in $Users) {
        Update-MgUser -UserId $User.UserPrincipalName -BodyParameter $params
    }
}
function checkUserAccountStatus {
    param(
        $UserId
    )
    return (Get-MgUser -UserId $UserId -Property AccountEnabled).AccountEnabled
}

<# Admin role section #>
function checkAdminRoleReport {
    Write-Host "Checking admin role assignments"
    $Assignments = Get-MgRoleManagementDirectoryRoleAssignment -Property PrincipalId, RoleDefinitionId
    foreach ($Assignment in $Assignments) {
        $ProcessedCount++
        Write-Progress -Activity "Processed count: $ProcessedCount; Currently processing: $($Assignment.PrincipalId)"
        if ($User = Get-MgUser -UserId $Assignment.PrincipalId -Property DisplayName, UserPrincipalName -ErrorAction SilentlyContinue) {
            $Assignment | Add-Member -NotePropertyName "DisplayName" -NotePropertyValue $User.DisplayName
            $Assignment | Add-Member -NotePropertyName "UserPrincipalName" -NotePropertyValue $User.UserPrincipalName
            $Assignment | Add-Member -NotePropertyName "RoleName" -NotePropertyValue (Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $Assignment.RoleDefinitionId -Property DisplayName).DisplayName
        }
    }
    Write-Progress -Activity "Processed count: $ProcessedCount; Currently processing: $($Assignment.PrincipalId)" -Status "Ready" -Completed
    return $Assignments | Where-Object { -not ($null -eq $_.DisplayName) } | Sort-Object -Property UserPrincipalName | ConvertTo-HTML -Property DisplayName, UserPrincipalName, RoleName -As Table -Fragment -PreContent "<h3>Admin role assignments</h3>"
}

<# BreakGlass account Section #>
function checkBreakGlassAccountReport {
    param (
        $Create
    )
    if ($BgAccount = getBreakGlassAccount) {
        return $BgAccount | ConvertTo-HTML -Property DisplayName, UserPrincipalName, AccountEnabled, GlobalAdmin -As Table -Fragment -PreContent "<br><h3>BreakGlass account</h3>"
    }
    if ($create) {
        createBreakGlassAccount
        return getBreakGlassAccount | ConvertTo-HTML -Property DisplayName, UserPrincipalName, AccountEnabled, GlobalAdmin -As Table -Fragment -PreContent "<br><h3>BreakGlass account</h3><p>Check console log for credentials</p>"
    }
    return "<br><h3>BreakGlass account</h3><p>Not found</p>"
}
function getBreakGlassAccount {
    Write-Host "Checking BreakGlass account"
    $BgAccounts = Get-MgUser -Filter "startswith(displayName, 'BreakGlass ')" -Property Id, DisplayName, UserPrincipalName, AccountEnabled
    if (-not $bgAccounts) { return }
    foreach ($BgAccount in $BgAccounts) {
        Add-Member -InputObject $BgAccount -NotePropertyName "GlobalAdmin" -NotePropertyValue (checkGlobalAdminRole $BgAccount.Id)
    }
    return $BgAccounts
}
function getGlobalAdminRoleId {
    return (Get-MgDirectoryRole -Filter "DisplayName eq 'Global Administrator'" -Property Id).Id
}
function checkGlobalAdminRole {
    param (
        $AccountId
    )
    if (Get-MgDirectoryRoleMember -DirectoryRoleId (getGlobalAdminRoleId) -Filter "id eq '$($AccountId)'") {
        return $true
    }
}
function createBreakGlassAccount {
    Write-Host "Creating BreakGlass account:"
    $Name = -join ((97..122) | Get-Random -Count 64 | ForEach-Object { [char]$_ })
    $DisplayName = "BreakGlass $Name"
    $Domain = (Get-MgDomain -Property id, IsInitial | Where-Object { $_.IsInitial -eq $true }).Id
    $UPN = "$Name@$Domain"
    $PasswordProfile = @{
        ForceChangePasswordNextSignIn        = $false
        ForceChangePasswordNextSignInWithMfa = $false
        Password                             = generatePassword
    }
    $BgAccount = New-MgUser -DisplayName $DisplayName -UserPrincipalName $UPN -MailNickName $Name -PasswordProfile $PasswordProfile -PreferredLanguage "en-US" -AccountEnabled
    $DirObject = @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($BgAccount.id)"
    }
    New-MgDirectoryRoleMemberByRef -DirectoryRoleId (getGlobalAdminRoleId) -BodyParameter $DirObject
    Add-Member -InputObject $BgAccount -NotePropertyName "Password" -NotePropertyValue $PasswordProfile.Password
    Write-Host ($BgAccount | Select-Object -Property Id, DisplayName, UserPrincipalName, Password | Format-List | Out-String)
}
function generatePassword {
    param (
        [ValidateRange(4, [int]::MaxValue)]
        [int] $length = 64,
        [int] $upper = 4,
        [int] $lower = 4,
        [int] $numeric = 4,
        [int] $special = 4
    )
    if ($upper + $lower + $numeric + $special -gt $length) {
        throw "number of upper/lower/numeric/special char must be lower or equal to length"
    }
    $uCharSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $lCharSet = "abcdefghijklmnopqrstuvwxyz"
    $nCharSet = "0123456789"
    $sCharSet = "/*-+, !?=()@; :._"
    $charSet = ""
    if ($upper -gt 0) { $charSet += $uCharSet }
    if ($lower -gt 0) { $charSet += $lCharSet }
    if ($numeric -gt 0) { $charSet += $nCharSet }
    if ($special -gt 0) { $charSet += $sCharSet }
    $charSet = $charSet.ToCharArray()
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[]($length)
    $rng.GetBytes($bytes)
    $result = New-Object char[]($length)
    for ($i = 0 ; $i -lt $length ; $i++) {
        $result[$i] = $charSet[$bytes[$i] % $charSet.Length]
    }
    $password = (-join $result)
    $valid = $true
    if ($upper -gt ($password.ToCharArray() | Where-Object { $_ -cin $uCharSet.ToCharArray() }).Count) { $valid = $false }
    if ($lower -gt ($password.ToCharArray() | Where-Object { $_ -cin $lCharSet.ToCharArray() }).Count) { $valid = $false }
    if ($numeric -gt ($password.ToCharArray() | Where-Object { $_ -cin $nCharSet.ToCharArray() }).Count) { $valid = $false }
    if ($special -gt ($password.ToCharArray() | Where-Object { $_ -cin $sCharSet.ToCharArray() }).Count) { $valid = $false }
    if (!$valid) {
        $password = Get-RandomPassword $length $upper $lower $numeric $special
    }
    return $password
}

<# User MFA section#>
function checkUserMfaStatusReport {
    Write-Host "Checking user MFA status"
    $Users = Get-MgUser -All -Filter "UserType eq 'Member'" -Property DisplayName, UserPrincipalName, AssignedLicenses, AccountEnabled
    $Users | ForEach-Object {
        $ProcessedCount++
        if (($_.AssignedLicenses).Count -ne 0) {
            $LicenseStatus = "Licensed"
        }
        else {
            $LicenseStatus = "Unlicensed"
        }
        Write-Progress -Activity "Processed count: $ProcessedCount; Currently processing: $($_.DisplayName)"
        [array]$MFAData = Get-MgUserAuthenticationMethod -UserId $_.UserPrincipalName
        $AuthenticationMethod = @()
        $AdditionalDetails = @()
        foreach ($MFA in $MFAData) { 
            Switch ($MFA.AdditionalProperties["@odata.type"]) { 
                "#microsoft.graph.passwordAuthenticationMethod" {
                    $AuthMethod = 'PasswordAuthentication'
                    $AuthMethodDetails = $MFA.AdditionalProperties["displayName"] 
                } 
                "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" {
                    $AuthMethod = 'AuthenticatorApp'
                    $AuthMethodDetails = $MFA.AdditionalProperties["displayName"] 
                }
                "#microsoft.graph.phoneAuthenticationMethod" {
                    $AuthMethod = 'PhoneAuthentication'
                    $AuthMethodDetails = $MFA.AdditionalProperties["phoneType", "phoneNumber"] -join ' '
                } 
                "#microsoft.graph.fido2AuthenticationMethod" {
                    $AuthMethod = 'Fido2'
                    $AuthMethodDetails = $MFA.AdditionalProperties["model"] 
                }  
                "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod" {
                    $AuthMethod = 'WindowsHelloForBusiness'
                    $AuthMethodDetails = $MFA.AdditionalProperties["displayName"] 
                }                        
                "#microsoft.graph.emailAuthenticationMethod" {
                    $AuthMethod = 'EmailAuthentication'
                    $AuthMethodDetails = $MFA.AdditionalProperties["emailAddress"] 
                }               
                "microsoft.graph.temporaryAccessPassAuthenticationMethod" {
                    $AuthMethod = 'TemporaryAccessPass'
                    $AuthMethodDetails = 'Access pass lifetime (minutes): ' + $MFA.AdditionalProperties["lifetimeInMinutes"] 
                }
                "#microsoft.graph.passwordlessMicrosoftAuthenticatorAuthenticationMethod" {
                    $AuthMethod = 'PasswordlessMSAuthenticator'
                    $AuthMethodDetails = $MFA.AdditionalProperties["displayName"]
                }
                "#microsoft.graph.softwareOathAuthenticationMethod" {
                    $AuthMethod = 'SoftwareOath'
                }
            }
            $AuthenticationMethod += $AuthMethod
            if ($null -ne $AuthMethodDetails) {
                $AdditionalDetails += "$AuthMethod : $AuthMethodDetails"
            }
        }
        $AuthenticationMethod = $AuthenticationMethod | Sort-Object | Get-Unique
        $AdditionalDetail = $AdditionalDetails -join ', '
        [array]$StrongMFAMethods = ("Fido2", "PhoneAuthentication", "PasswordlessMSAuthenticator", "AuthenticatorApp", "WindowsHelloForBusiness")
        $MFAStatus = "Disabled"

        foreach ($StrongMFAMethod in $StrongMFAMethods) {
            if ($AuthenticationMethod -contains $StrongMFAMethod) {
                $MFAStatus = "Strong"
                break
            }
        }
        if ( $AuthenticationMethod -contains "SoftwareOath") {
            $MFAStatus = "Weak"
        }
        Add-Member -InputObject $_ -NotePropertyName "LicenseStatus" -NotePropertyValue $LicenseStatus
        Add-Member -InputObject $_ -NotePropertyName "MFAStatus" -NotePropertyValue $MFAStatus
        Add-Member -InputObject $_ -NotePropertyName "AdditionalDetail" -NotePropertyValue $AdditionalDetail
    }
    Write-Progress -Activity "Processed count: $ProcessedCount; Currently processing: $($_.DisplayName)" -Status "Ready" -Completed
    $Users | Sort-Object -Property UserPrincipalName | ConvertTo-HTML -Property DisplayName, UserPrincipalName, LicenseStatus, AccountEnabled, MFAStatus, AdditionalDetail -As Table -Fragment -PreContent "<br><h3>User MFA status</h3>"
}

<# Security Defaults section #>
function checkSecurityDefaultsReport {
    param (
        [System.Boolean]$EnableSecurityDefaults,
        [System.Boolean]$DisableSecurityDefaults
    )
    if ($EnableSecurityDefaults -and (-not $DisableSecurityDefaults)) {
        updateSecurityDefaults -Enable $true
    }  
    if ($DisableSecurityDefaults -and (-not $EnableSecurityDefaults)) {
        updateSecurityDefaults -Enable $false
    }
    if (checkSecurityDefaults) {
        return "<br><h3>Security Defaults</h3><p>Enabled</p>"
    }
    return "<br><h3>Security Defaults</h3><p>Disabled</p>"
}
function checkSecurityDefaults {
    Write-Host "Checking Security Defaults"
    return (Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy -Property "isEnabled").IsEnabled
}
function updateSecurityDefaults {
    param ([System.Boolean]$Enable)
    $params = @{
        IsEnabled = $Enable
    }
    Write-Host "Updating Security Defaults enable:" $Enable
    Update-MgPolicyIdentitySecurityDefaultEnforcementPolicy -BodyParameter $params
}

<# Conditional Access section #>
function getConditionalAccessPolicy {
    Write-Host "Checking Conditional Access policies"
    return Get-MgIdentityConditionalAccessPolicy -Property Id, DisplayName, State
}
function checkConditionalAccessPolicyReport {
    if ($Policy = getConditionalAccessPolicy) {
        return $Policy | ConvertTo-HTML -Property DisplayName, Id, State -As Table -Fragment -PreContent "<br><h3>Conditional Access policies</h3>"
    }
    return "<br><h3>Conditional Access policies</h3><p>Not found</p>"
}

# function deleteConditionalAccessPolicy {
#     param (
#         [Parameter(Mandatory = $true)]
#         $Policies
#     )
#     foreach ($Policy in $Policies) {
#         Write-Host "Removing existing Conditional Access policies"
#         Remove-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $Policy.Id
#     }
# }

# function cleanUpConditionalAccessPolicy {
#     $Policies = getConditionalAccessPolicy
#     deleteConditionalAccessPolicy $Policies
# }

# function getNamedLocations {
#     return Get-MgIdentityConditionalAccessNamedLocation -Property Id, DisplayName
# }

# function createConditionalAccessPolicy {
#     $params = @{
#         DisplayName   = "Require MFA from all unknown locations"
#         State         = "enabled"
#         Conditions    = @{
#             Applications = @{
#                 IncludeApplications = @(
#                     "All"
#                 )
#             }
#             Users        = @{
#                 IncludeUsers = @(
#                     "All"
#                 )
#                 ExcludeUsers = @(
#                     getBreakGlassAccount.Id
#                 )
#             }
#             Locations    = @{
#                 IncludeLocations = @(
#                     "All"
#                 )
#                 ExcludeLocations = @(
#                     "AllTrusted"
#                 )
#             }
#         }
#         GrantControls = @{
#             Operator        = "OR"
#             BuiltInControls = @(
#                 "mfa"
#             )
#         }
#     }
#     New-MgIdentityConditionalAccessPolicy -BodyParameter $params
# }

<# Application protection polices section#>
function checkAppProtectionPolicesReport {
    Write-Host "Checking App protection policies"
    if ($Polices = getAppProtectionPolices) {
        return $Polices | ConvertTo-HTML -As Table -Property DisplayName, IsAssigned -Fragment -PreContent "<br><h3>App protection policies</h3>"
    }
    return "<br><h3>App protection policies</h3><p>Not found</p>"
}
function getAppProtectionPolices {
    $IOSPolicies = Get-MgDeviceAppManagementiOSManagedAppProtection -Property DisplayName, IsAssigned
    $AndroidPolicies = Get-MgDeviceAppManagementAndroidManagedAppProtection -Property DisplayName, IsAssigned
    $Policies = @()
    $Policies += $IOSPolicies
    $Policies += $AndroidPolicies
    return $Policies
}
# function createAndroidAppProtectionPolicy {
#     $Body = @{
#         "@odata.type" = "#microsoft.graph.androidManagedAppProtection"
#         displayName = "Test"
#     }
#     New-MgDeviceAppManagementAndroidManagedAppProtection -BodyParameter $Body
# }

<# Enterprise Application section #>
function checkApplicationConsentPolicyReport {
    param(
        [System.Boolean]$DisableUserConsent
    )
    if ($DisableUserConsent) { disableApplicationUserConsent }
    Write-Host "Checking Enterprise Application consent policy"
    $Policy = (Get-MgPolicyAuthorizationPolicy -Property DefaultUserRolePermissions).DefaultUserRolePermissions.PermissionGrantPoliciesAssigned
    if ($Policy -eq "ManagePermissionGrantsForSelf.microsoft-user-default-legacy" ) {
        return "<br><h3>Enterprise Application user consent policy</h3><p>Allow user consent for all apps: $($Policy)</p>"
    }  
    if ($Policy -eq "ManagePermissionGrantsForSelf.microsoft-user-default-low" ) {
        return "<br><h3>Enterprise Application user consent policy</h3><p>Allow user consent for well known apps: $($Policy)</p>"
    }
    return "<br><h3>Enterprise Application user consent policy</h3><p>Do not allow user consent</p>"
}
function disableApplicationUserConsent {
    Write-Host "Disable Enterprise Application user consent"
    Update-MgPolicyAuthorizationPolicy -DefaultUserRolePermissions @{
        "PermissionGrantPoliciesAssigned" = @() 
    }
}

<# SharePoint Tenant section #>
function checkSpoTenantReport {
    param(
        [System.Boolean]$DisableAddToOneDrive
    )
    Write-Host "Checking SharePoint Online Tenant"
    if ($DisableAddToOneDrive) {
        Write-Host "Disable add to OneDrive button"
        Set-PnPTenant -DisableAddToOneDrive $True
    }
    Get-PnPTenant | ConvertTo-HTML -As List -Property DisableAddToOneDrive, ConditionalAccessPolicy -Fragment -PreContent "<h3>Tenant settings</h3>"
}

<# User mailbox section #>
function checkMailboxReport {
    param(
        [System.Boolean]$Language
    )
    Write-Host "Checking user mailboxes"
    if ( -not ($Mailboxes = Get-EXOMailbox -RecipientTypeDetails UserMailbox -ResultSize:Unlimited -Properties DisplayName, UserPrincipalName)) {
        return "<br><h3>user mailbox report</h3><p>Not found</p>"
    }
    if ($Language) {
        setMailboxLang -Mailbox $Mailboxes
    }
    $MailboxReport = @()
    foreach ($Mailbox in $Mailboxes) {
        $ProcessedCount++
        Write-Progress -Activity "Processed count: $ProcessedCount; Currently processing: $($Mailbox.DisplayName)"
        $MailboxReport += checkMailboxLoginAndLocation $Mailbox
    }
    Write-Progress -Activity "Processed count: $ProcessedCount; Currently processing: $($Mailbox.DisplayName)" -Status "Ready" -Completed
    return $MailboxReport | ConvertTo-HTML -As Table -Property UserPrincipalName, DisplayName, Language, TimeZone, LoginAllowed `
        -Fragment -PreContent "<h3>User mailbox report</h3>"
}
function setMailboxLang {
    param(
        $Mailbox
    )
    Write-Host "Setting mailboxes language:" $script:MailboxLanguageCode "timezone:" $script:MailboxTimeZone
    $Mailbox | Set-MailboxRegionalConfiguration -LocalizeDefaultFolderName:$true -Language $script:MailboxLanguageCode -TimeZone $script:MailboxTimeZone
}

<# Shared mailbox section #>
function checkSharedMailboxReport {
    param(
        [System.Boolean]$Language,
        [System.Boolean]$DisableLogin,
        [System.Boolean]$EnableCopy
    )
    Write-Host "Checking shared mailboxes"
    if ( -not ($Mailboxes = Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize:Unlimited -Properties DisplayName,
            UserPrincipalName, MessageCopyForSentAsEnabled, MessageCopyForSendOnBehalfEnabled)) {
        return "<br><h3>Shared mailbox report</h3><p>Not found</p>"
    }
    if ($Language) { setMailboxLang -Mailbox $Mailboxes }
    if ($DisableLogin) { disableUserAccount $Mailboxes }
    if ($EnableCopy) {
        setSharedMailboxEnableCopyToSent $Mailboxes
        $Mailboxes = Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize:Unlimited -Properties DisplayName,
        UserPrincipalName, MessageCopyForSentAsEnabled, MessageCopyForSendOnBehalfEnabled
    }
    $MailboxReport = @()
    foreach ($Mailbox in $Mailboxes) {
        $ProcessedCount++
        Write-Progress -Activity "Processed count: $ProcessedCount; Currently processing: $($Mailbox.DisplayName)"
        $MailboxReport += checkMailboxLoginAndLocation $Mailbox
    }
    Write-Progress -Activity "Processed count: $ProcessedCount; Currently processing: $($Mailbox.DisplayName)" -Status "Ready" -Completed
    return $MailboxReport | ConvertTo-HTML -As Table -Property UserPrincipalName, DisplayName, Language, TimeZone, MessageCopyForSentAsEnabled,
    MessageCopyForSendOnBehalfEnabled, LoginAllowed `
        -Fragment -PreContent "<br><h3>Shared mailbox report</h3>"
}
function checkMailboxLoginAndLocation {
    param (
        $Mailbox
    )
    $ReginalConfig = $Mailbox | Get-MailboxRegionalConfiguration
    Add-Member -InputObject $Mailbox -NotePropertyName "Language" -NotePropertyValue $ReginalConfig.Language
    Add-Member -InputObject $Mailbox -NotePropertyName "TimeZone" -NotePropertyValue $ReginalConfig.TimeZone
    Add-Member -InputObject $Mailbox -NotePropertyName "LoginAllowed" -NotePropertyValue (checkUserAccountStatus $Mailbox.UserPrincipalName)
    return $Mailbox
}
function setSharedMailboxEnableCopyToSent {
    param(
        $Mailbox
    )
    Write-Host "Enable shared mailbox copy to sent"
    $Mailbox | Set-Mailbox -MessageCopyForSentAsEnabled $True -MessageCopyForSendOnBehalfEnabled $True
}

<# Unified mailbox section #>
function checkUnifiedMailboxReport {
    param(
        [System.Boolean]$HideFromClient
    )
    Write-Host "Checking unified mailboxes"
    if ( -not ($Mailboxes = Get-UnifiedGroup -ResultSize Unlimited)) {
        return "<br><h3>Unified mailbox report</h3><p>Not found</p>"
    }
    if ($HideFromClient) {
        Write-Host "Hiding unified mailboxes from outlook client"
        $Mailboxes | Set-UnifiedGroup -HiddenFromExchangeClientsEnabled:$true -HiddenFromAddressListsEnabled:$false
        $Mailboxes = Get-UnifiedGroup -ResultSize Unlimited 
    }
    return $Mailboxes | Sort-Object -Property PrimarySmtpAddress | ConvertTo-HTML -As Table -Property DisplayName, PrimarySmtpAddress, HiddenFromAddressListsEnabled, HiddenFromExchangeClientsEnabled -Fragment -PreContent "<br><h3>Unified mailbox report</h3>"
}

<# Script logic start section #>
CheckInteractiveMode -Parameters $PSBoundParameters
if ($script:InteractiveMode) {
    InteractiveMenu
}

connectGraph
if ($script:AddSharePointOnlineReport -or $script:DisableAddToOneDrive) { connectSpo }
if ($script:AddExchangeOnlineReport -or $script:SetMailboxLanguage -or $script:DisableSharedMailboxLogin -or $script:EnableSharedMailboxCopyToSent -or $script:HideUnifiedMailboxFromOutlookClient) { connectExo }

$Report = @()
$Report += organizationReport
$Report += "<br><hr><h2>Azure Active Directory</h2>"
$Report += checkAdminRoleReport
$Report += checkBreakGlassAccountReport -Create $script:CreateBreakGlassAccount
$Report += checkUserMfaStatusReport
$Report += checkSecurityDefaultsReport -Enable $script:EnableSecurityDefaults -Disable $script:DisableSecurityDefaults
$Report += checkConditionalAccessPolicyReport
$Report += checkAppProtectionPolicesReport
$Report += checkApplicationConsentPolicyReport -DisableUserConsent $script:DisableEnterpiseApplicationUserConsent

if ($script:AddSharePointOnlineReport -or $script:DisableAddToOneDrive) {
    $Report += "<br><hr><h2>SharePoint Online</h2>"
    $Report += checkSpoTenantReport -DisableAddToOneDrive $script:DisableAddToOneDrive
}
if ($script:AddExchangeOnlineReport -or $script:SetMailboxLanguage -or $script:DisableSharedMailboxLogin -or $script:EnableSharedMailboxCopyToSent -or $script:HideUnifiedMailboxFromOutlookClient) {
    $Report += "<br><hr><h2>Exchange Online</h2>"
    $Report += checkMailboxReport -Language $script:SetMailboxLanguage
    $Report += checkSharedMailboxReport -Language $script:SetMailboxLanguage -DisableLogin $script:DisableSharedMailboxLogin -EnableCopy $script:EnableSharedMailboxCopyToSent
    $Report += checkUnifiedMailboxReport -HideFromClient $script:HideUnifiedMailboxFromOutlookClient
}
if ($script:ExoConnected -and (-not $KeepExoSessionAlive)) {
    disconnectExo
}
if ($script:GraphConnected -and (-not $KeepGraphSessionAlive)) {
    disconnectGraph
}
if ($script:SpoConnected -and (-not $KeepSpoSessionAlive)) {
    disconnectSpo
}

<# CSS styles section #>
$Header = @"
<title>$($ReportTitle)</title>
<link rel="icon" type="image/png" href="$($ReportImageUrl)">
<style>
html {
    display: table;
    margin: auto;
}
body {
    display: table-cell;
    vertical-align: middle;
    padding-right: 200px;
    padding-left: 200px;
}
h1 {
    font-family: Arial, Helvetica, sans-serif;
    color: #666666;
    font-size: 32px;
}
h2 {
    font-family: Arial, Helvetica, sans-serif;
    color: #666666;
    font-size: 24px;
}
h3 {
    font-family: Arial, Helvetica, sans-serif;
    color: #666666;
    font-size: 16px;
    
}
p {
    font-family: Arial, Helvetica, sans-serif;
    font-size: 14px;
}
table {
    font-size: 14px;
    border: 0px;
    font-family: Arial, Helvetica, sans-serif;
    border-collapse: collapse;
    margin: 25px 0;
    min-width: 400px;
    box-shadow: 0 0 20px rgba(0, 0, 0, 0.15);
}
th,
td {
    padding: 4px;
    margin: 0px;
    border: 0;
    padding: 12px 15px;
}
th {
    background: #666666;
    color: #fff;
    font-size: 11px;
    padding: 10px 15px;
    vertical-align: middle;
}
tbody tr:nth-child(even) {
    background: #f0f0f2;
}
thead tr {
    color: #ffffff;
    text-align: left;
}
tbody tr {
    border-bottom: 1px solid #dddddd;
}
tbody tr:nth-of-type(even) {
    background-color: #f3f3f3;
}
#CreationDate {
font-family: Arial, Helvetica, sans-serif;
color: #666666;
font-size: 12px;
}
</style>
"@

<# HTML report section #>
$Desktop = [Environment]::GetFolderPath("Desktop")

$ReportTitleHtml = "<h1>" + $ReportTitle + "</h1>"
$ReportName = ("Microsoft365-Report-$($script:CustomerName).html").Replace(" ", "")

$PostContentHtml = @"
<p id='CreationDate'>Creation date: $(Get-Date)</p>
<img src="$($LogoImageUrl)" width='75'>
"@

Write-Host "Generating HTML report:" $ReportName
$Report = ConvertTo-HTML -Body "$ReportTitleHtml $Report" -Title $ReportTitle -Head $Header -PostContent $PostContentHtml
$Report | Out-File $Desktop\$ReportName
Invoke-Item $Desktop\$ReportName
if ($script:InteractiveMode -and $script:CreateBreakGlassAccount) { Read-Host "Click [ENTER] key to exit AzureAdDeployer" }