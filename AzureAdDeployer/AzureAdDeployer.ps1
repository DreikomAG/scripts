# Maintainer: https://github.com/swissbuechi
[CmdletBinding()]
Param(
    [switch]$Install,
    [switch]$UseExistingExoSession,   
    [switch]$KeepExoSessionAlive,    
    [switch]$UseExistingGraphSession,
    [switch]$KeepGraphSessionAlive,
    [switch]$AddExchangeOnlineReport,
    [switch]$CreateBreakGlassAccount,
    [switch]$EnableSecurityDefaults,
    [switch]$DisableSecurityDefaults
)
$Version = "1.0.0"
$script:ExoConnected = $false
$script:GraphConnected = $false

Write-Host "AzureAdDeployer version " $Version

$Desktop = [Environment]::GetFolderPath("Desktop")

$ReportTitle = "Security report"
$ReportTitleHtml = "<h1>" + $ReportTitle + "</h1>"

$PostContentHtml = "<p id='CreationDate'>Creation date: $(Get-Date)</p>"

<# Install modules section #>
function installEXO {
    if (Get-Module -Name ExchangeOnlineManagement -ListAvailable) {
        Write-Host "Updating PowerShell Exchange Online module"
        Update-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
    }

    if (-not (Get-Module -Name ExchangeOnlineManagement -ListAvailable)) {
        Write-Host "Installing PowerShell Exchange Online module"
        Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
    }
}

function installGraph {
    if (Get-Module -Name Microsoft.Graph -ListAvailable) {
        Write-Host "Updating PowerShell Graph SDK module"
        Update-Module -Name Microsoft.Graph -Scope CurrentUser -Force
    }

    if (-not (Get-Module -Name Microsoft.Graph -ListAvailable)) {
        Write-Host "Installing PowerShell Graph SDK module"
        Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force
    }
}
    
<# Connect sessions section #>
function connectGraph {
    if ($UseExistingGraphSession) { return }
    if (-not $script:GraphConnected) {
        Write-Host "Connecting to Graph"
        Connect-MgGraph -Scopes "Policy.Read.All, Policy.ReadWrite.ConditionalAccess, Application.Read.All,
        User.Read.All, User.ReadWrite.All, Domain.Read.All, Directory.Read.All, Directory.ReadWrite.All,
        RoleManagement.ReadWrite.Directory"
    }
    $script:GraphConnected = $true
}

function connectExo {
    if ($UseExistingExoSession) { return }
    if (-not $script:ExoConnected) {
        Write-Host "Connecting Exchange Online PowerShell session"
        # Connect-ExchangeOnline -ShowBanner:$false -Device
        Connect-ExchangeOnline -ShowBanner:$false
    }
    $script:ExoConnected = $true
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
        Disconnect-Graph
    }
    $script:GraphConnected = $false
}

<# User Account section #>
function disableUserAccount {
    param (
        $UserId
    )
    $params = @{
        AccountEnabled = "false"
    }
    Update-MgUser -UserId $UserId -BodyParameter $params
}

function checkUserAccountStatus {
    param(
        $UserId
    )
    return (Get-MgUser -UserId $UserId -Property AccountEnabled).AccountEnabled
}

 <# BreakGlass account Section #>
function checkBreakGlassAccountReport {
    param (
        $Create
    )
    if ($BgAccount = getBreakGlassAccount) {
        return $BgAccount | ConvertTo-HTML -Property DisplayName, UserPrincipalName, GlobalAdmin -As Table -Fragment -PreContent "<h3>BreakGlass Account found</h3>"
    }
    if ($create) {
        createBreakGlassAccount
        return $BgAccount | ConvertTo-HTML -Property DisplayName, UserPrincipalName, GlobalAdmin -As Table -Fragment -PreContent "<h3>BreakGlass Account created</h3><p>Check console log for credentials</p>"
    }
    return "<h3>BreakGlass account not found</h3><p>Create account with <code> -CreateBreakGlassAccount </code></p>"
}

function getBreakGlassAccount {
    Write-Host "Checking BreakGlass account"
    $BgAccounts = Get-MgUser -Filter "startswith(displayName,'BreakGlass ')" -Property Id, DisplayName, UserPrincipalName
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
    Write-Host "Checking Global Admin role"
    if (Get-MgDirectoryRoleMember -DirectoryRoleId (getGlobalAdminRoleId) -Filter "id eq '$($AccountId)'") {
        return $true
    }
}

function createBreakGlassAccount {
    Write-Output "Creating BreakGlass account:"
    $Name = -join ((97..122) | Get-Random -Count 64 | % { [char]$_ })
    $DisplayName = "BreakGlass $Name"
    $Domain = (Get-MgDomain -Property id, IsInitial | Where-Object {$_.IsInitial -eq $true}).Id
    $UPN = "$Name@$Domain"
    $PasswordProfile = @{
        ForceChangePasswordNextSignIn = $false
        ForceChangePasswordNextSignInWithMfa = $false
        Password = generatePassword
    }
    $BgAccount = New-MgUser -DisplayName $DisplayName -UserPrincipalName $UPN -MailNickName $Name -PasswordProfile $PasswordProfile -PreferredLanguage "en-US" -AccountEnabled
    $DirObject = @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($BgAccount.id)"
    }
    New-MgDirectoryRoleMemberByRef -DirectoryRoleId getGlobalAdminRoleId -BodyParameter $DirObject
    $BgAccountDisplay = [pscustomobject]@{
        DisplayName                       = $DisplayName
        UserPrincipalName                 = $UPN
        # Password                          = ConvertFrom-SecureString $PasswordProfile.Password -AsPlainText
        Password                          = $PasswordProfile.Password
    }
    Write-Host ($BgAccountDisplay | Format-List | Out-String)
}

function generatePassword {
    param(
        [ValidateRange(12, 256)]
        [int]
        $length = 64
    )
    $symbols = '!@#$%&*'.ToCharArray()
    $characterList = 'a'..'z' + 'A'..'Z' + '0'..'9' + $symbols
    do {
        $password = -join (0..$length | % { $characterList | Get-Random })
        [int]$hasLowerChar = $password -cmatch '[a-z]'
        [int]$hasUpperChar = $password -cmatch '[A-Z]'
        [int]$hasDigit = $password -match '[0-9]'
        [int]$hasSymbol = $password.IndexOfAny($symbols) -ne -1
    }
    until (($hasLowerChar + $hasUpperChar + $hasDigit + $hasSymbol) -ge 4)
    # $password | ConvertTo-SecureString -AsPlainText
    $password
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
        return "<br><h3>Security Defaults enabled</h3>"
    }
    return "<br><h3>Security Defaults disabled</h3>"
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
        return $Policy | ConvertTo-HTML -Property DisplayName, Id, State -As Table -Fragment -PreContent "<br><h3>Conditional Access policies found</h3>"
    }
    return "<br><h3>Conditional Access policies not found</h3>"
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

<# Shared Mailbox section #>
function getSharedMailboxes {
    return Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize:Unlimited -Properties DisplayName,
    UserPrincipalName, MessageCopyForSentAsEnabled, MessageCopyForSendOnBehalfEnabled
}

function checkSharedMailboxLogin {
    param (
        $Mailbox
    )
    $ReginalConfig = $Mailbox | Get-MailboxRegionalConfiguration
    Add-Member -InputObject $Mailbox -NotePropertyName "Language" -NotePropertyValue $ReginalConfig.Language
    Add-Member -InputObject $Mailbox -NotePropertyName "TimeZone" -NotePropertyValue $ReginalConfig.TimeZone
    Add-Member -InputObject $Mailbox -NotePropertyName "LoginAllowed" -NotePropertyValue (checkUserAccountStatus $Mailbox.UserPrincipalName)
    return $Mailbox
}

function checkSharedMailboxReport {
    param(
        [System.Boolean]$Fix
    )
    Write-Host "Checking Shared Mailboxes"
    $MailboxReport = @()
    foreach ($Mailbox in getSharedMailboxes) {
        if ($Fix) {
            setSharedMailboxEnableCopyToSent $Mailbox
            setMailboxLang $Mailbox
            disableUserAccount $Mailbox.UserPrincipalName
        }
        $MailboxReport += checkSharedMailboxLogin $Mailbox
    }
    return $MailboxReport | ConvertTo-HTML -As Table -Property UserPrincipalName, DisplayName, Language, TimeZone, MessageCopyForSentAsEnabled,
    MessageCopyForSendOnBehalfEnabled, LoginAllowed `
        -Fragment -PreContent "<br><h3>Shared Mailbox report</h3>"
}

function setSharedMailboxEnableCopyToSent {
    param(
        $Mailbox
    )
    $Mailbox | Set-Mailbox -MessageCopyForSentAsEnabled $True -MessageCopyForSendOnBehalfEnabled $True
}

<# User Mailbox section #>
function checkMailboxReport {
    param(
        [System.Boolean]$Fix
    )
    Write-Host "Checking User Mailboxes"
    $Mailboxes = Get-EXOMailbox -ResultSize:Unlimited
    if ($Fix) {
        $Mailboxes | setMailboxLang
    }
    return $Mailboxes | Get-MailboxRegionalConfiguration | ConvertTo-HTML -As Table -Property Identity, Language, TimeZone `
        -Fragment -PreContent "<h3>User Mailbox report</h3> <p>Set language to de-CH with <code> -FixMailboxLanguage </code></p>"
}

function setMailboxLang {
    param(
        $Mailbox
    )
    Write-Host "Updating Mailbox language"
    $Mailbox | Set-MailboxRegionalConfiguration -LocalizeDefaultFolderName:$true -Language de-CH -TimeZone "W. Europe Standard Time" 
}

<# Script logic start section #>
if ($Install) {
    Write-Host "Installing prerequisites"
    installEXO
    installGraph
    return
}

if ($AddExchangeOnlineReport) { connectExo }
connectGraph

$Report = @()

$Report += "<br><h2>Azure Active Directory security settings</h2>"
$Report += checkBreakGlassAccountReport -Create $CreateBreakGlassAccount
$Report += checkSecurityDefaultsReport -Enable $EnableSecurityDefaults -Disable $DisableSecurityDefaults
$Report += checkConditionalAccessPolicyReport

if ($AddExchangeOnlineReport) {
    $Report += "<br><h2>Exchange Online security settings</h2>"
    $Report += checkMailboxReport -FixLanguage $ApplyFixMailboxLanguage
    $Report += checkSharedMailboxReport -FixLanguage $ApplyFixMailboxLanguage -FixLogin $ApplyFixSharedMailboxLogin
}

if ($script:ExoConnected -and (-not $KeepExoSessionAlive)) {
    disconnectExo
}

if ($script:GraphConnected -and (-not $KeepGraphSessionAlive)) {
    disconnectGraph
}

<# CSS styles section #>
$Header = @"
<style>
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
    font-size: 12px;
}

table {
    font-size: 12px;
    border: 0px;
    font-family: Arial, Helvetica, sans-serif;
}

td {
    padding: 4px;
    margin: 0px;
    border: 0;
}

th {
    background: #666666;
    color: #fff;
    font-size: 11px;
    text-transform: uppercase;
    padding: 10px 15px;
    vertical-align: middle;
}

tbody tr:nth-child(even) {
    background: #f0f0f2;
}

#CreationDate {

    font-family: Arial, Helvetica, sans-serif;
    color: #666666;
    font-size: 12px;
}

.StopStatus {

    color: #ff0000;
}

.RunningStatus {
    
    color: #008000;
}
</style>
"@

<# HTML report section #>
Write-Host "Generating HTML report"
$Report = ConvertTo-HTML -Body "$ReportTitleHtml $Report" -Title $ReportTitle -Head $Header -PostContent $PostContentHtml
$Report | Out-File $Desktop\AzureAdDeployer-Report.html
Invoke-Item $Desktop\AzureAdDeployer-Report.html
Read-Host "Click [ENTER] key to exit AzureAdDeployer"