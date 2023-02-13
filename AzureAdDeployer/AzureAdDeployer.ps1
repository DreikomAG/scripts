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
    [switch]$DisableSecurityDefaults,
    [switch]$SetMailboxLanguage,
    [switch]$DisableSharedMailboxLogin,
    [switch]$EnableSharedMailboxCopyToSent
)
$Version = "2.0.0"
$script:ExoConnected = $false
$script:GraphConnected = $false
$script:InteractiveMode = $false
$script:MailboxLanguageCode = "de-CH"
$script:MailboxTimeZone = "W. Europe Standard Time" 

$script:CreateBreakGlassAccount = $CreateBreakGlassAccount
$script:EnableSecurityDefaults = $EnableSecurityDefaults
$script:DisableSecurityDefaults = $DisableSecurityDefaults
$script:SetMailboxLanguage = $SetMailboxLanguage
$script:DisableSharedMailboxLogin = $DisableSharedMailboxLogin
$script:EnableSharedMailboxCopyToSent = $EnableSharedMailboxCopyToSent
$script:AddExchangeOnlineReport = $AddExchangeOnlineReport

Write-Host "AzureAdDeployer version " $Version

$Desktop = [Environment]::GetFolderPath("Desktop")

$ReportImageUrl = "https://cdn-icons-png.flaticon.com/512/3540/3540926.png"

$ReportTitle = "M365 Security Report"
# $ReportTitleHtml = "<div class='header'><h1>" + $ReportTitle + "</h1><img src='" + $ReportImageUrl + "' width='25' height='25'></div>"
$ReportTitleHtml = "<h1>" + $ReportTitle + "</h1>"

$PostContentHtml = "<p id='CreationDate'>Creation date: $(Get-Date)</p>"

<# Interactive inputs section #>
function CheckInteractiveMode {
    Param(
        $Parameters
    )
    if ($Parameters.Count) {
        return
    }
    Write-Host "Interactive mode active"
    $script:InteractiveMode = $true
}

function InteractiveMenu {
    $StartOptionValue = 0
    $script:AddExchangeOnlineReport = $true
    while ($result -ne $StartOptionValue) {
        $Title = ""
        $Message = ""
        $Status = @"
1: Add Exchange Online report: $($script:AddExchangeOnlineReport)
2: Create BreakGlass account: $($script:CreateBreakGlassAccount)
3: Enable Security Defaults: $($script:EnableSecurityDefaults)
4: Disable Security Defaults: $($script:DisableSecurityDefaults)
5: Set mailbox language: $($script:SetMailboxLanguage)
6: Disable shared mailbox login: $($script:DisableSharedMailboxLogin)
7: Enable shared mailbox copy to sent: $($script:EnableSharedMailboxCopyToSent)
0: Start
"@
        $StartOption = New-Object System.Management.Automation.Host.ChoiceDescription "&0", "Start"
        $AddExchangeOnlineReportOption = New-Object System.Management.Automation.Host.ChoiceDescription "&1", "Add Exchange Online report"
        $CreateBreakGlassAccountOption = New-Object System.Management.Automation.Host.ChoiceDescription "&2", "Create BreakGlass account"
        $EnableSecurityDefaultsOption = New-Object System.Management.Automation.Host.ChoiceDescription "&3", "Enable Security Defaults"
        $DisableSecurityDefaultsOption = New-Object System.Management.Automation.Host.ChoiceDescription "&4", "Disable Security Defaults"
        $SetMailboxLanguageOption = New-Object System.Management.Automation.Host.ChoiceDescription "&5", "Set mailbox language"
        $DisableSharedMailboxLoginOption = New-Object System.Management.Automation.Host.ChoiceDescription "&6", "Disable shared mailbox login"
        $EnableSharedMailboxCopyToSentOption = New-Object System.Management.Automation.Host.ChoiceDescription "&7", "Enable shared mailbox copy to sent"

        $Options = [System.Management.Automation.Host.ChoiceDescription[]]($StartOption, $AddExchangeOnlineReportOption, $CreateBreakGlassAccountOption, $EnableSecurityDefaultsOption, $DisableSecurityDefaultsOption, $SetMailboxLanguageOption, $DisableSharedMailboxLoginOption, $EnableSharedMailboxCopyToSentOption)
        Write-Host $Status
        $result = $host.ui.PromptForChoice($Title, $Message, $Options, $StartOptionValue)
        switch ($result) {
            0 {"Starting AzureAdDeployer"}
            1 {$script:AddExchangeOnlineReport = ! $script:AddExchangeOnlineReport}
            2 {$script:CreateBreakGlassAccount = ! $script:CreateBreakGlassAccount}
            3 {$script:EnableSecurityDefaults = ! $script:EnableSecurityDefaults}
            4 {$script:DisableSecurityDefaults = ! $script:DisableSecurityDefaults}
            5 {$script:SetMailboxLanguage = ! $script:SetMailboxLanguage}
            6 {$script:DisableSharedMailboxLogin = ! $script:DisableSharedMailboxLogin}
            7 {$script:EnableSharedMailboxCopyToSent = ! $script:EnableSharedMailboxCopyToSent}
        }
    }
}

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

##TODO: Always check if Modules are installed before run
    
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
        Disconnect-Graph | Out-Null
    }
    $script:GraphConnected = $false
}

<# Customer infos#>
function organizationReport {
    return Get-MgOrganization -Property DisplayName, Id | ConvertTo-HTML -Property DisplayName, Id -As Table -Fragment
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
        return getBreakGlassAccount | ConvertTo-HTML -Property DisplayName, UserPrincipalName, GlobalAdmin -As Table -Fragment -PreContent "<h3>BreakGlass Account created</h3><p>Check console log for credentials</p>"
    }
    return "<h3>BreakGlass account not found</h3>"
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
    $sCharSet = "/*-+,!?=()@;:._"
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

<# Enterprise Application section #>

##TODO: https://learn.microsoft.com/en-us/azure/active-directory/manage-apps/configure-user-consent?pivots=ms-powershell

<# Shared mailbox section #>
function checkSharedMailboxReport {
    param(
        [System.Boolean]$Language,
        [System.Boolean]$DisableLogin,
        [System.Boolean]$EnableCopy
    )
    Write-Host "Checking shared mailboxes"
    $Mailboxes = Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize:Unlimited -Properties DisplayName,
    UserPrincipalName, MessageCopyForSentAsEnabled, MessageCopyForSendOnBehalfEnabled
    if ($Language) { setMailboxLang -Mailbox $Mailboxes }
    if ($DisableLogin) { disableUserAccount $Mailboxes }
    if ($EnableCopy) {
        setSharedMailboxEnableCopyToSent $Mailboxes
        $Mailboxes = Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize:Unlimited -Properties DisplayName,
        UserPrincipalName, MessageCopyForSentAsEnabled, MessageCopyForSendOnBehalfEnabled
    }
    $MailboxReport = @()
    foreach ($Mailbox in $Mailboxes) {
        $MailboxReport += checkMailboxLoginAndLocation $Mailbox
    }
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

<# User mailbox section #>
function checkMailboxReport {
    param(
        [System.Boolean]$Language
    )
    Write-Host "Checking user mailboxes"
    $Mailboxes = Get-EXOMailbox -RecipientTypeDetails UserMailbox -ResultSize:Unlimited -Properties DisplayName, UserPrincipalName
    if ($Language) {
        setMailboxLang -Mailbox $Mailboxes
    }
    $MailboxReport = @()
    foreach ($Mailbox in $Mailboxes) {
        $MailboxReport += checkMailboxLoginAndLocation $Mailbox
    }
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

<# Script logic start section #>

CheckInteractiveMode -Parameters $PSBoundParameters

if ($script:InteractiveMode) {
    InteractiveMenu
}

if ($Install) {
    Write-Host "Installing prerequisites"
    installGraph
    installEXO
    return
}

connectGraph
if ($script:AddExchangeOnlineReport -or $script:SetMailboxLanguage -or $script:DisableSharedMailboxLogin -or $script:EnableSharedMailboxCopyToSent) { connectExo }

$Report = @()

$Report += organizationReport
$Report += "<br><hr><h2>Azure Active Directory</h2>"
$Report += checkBreakGlassAccountReport -Create $script:CreateBreakGlassAccount
$Report += checkSecurityDefaultsReport -Enable $script:EnableSecurityDefaults -Disable $script:DisableSecurityDefaults
$Report += checkConditionalAccessPolicyReport

if ($script:AddExchangeOnlineReport -or $script:SetMailboxLanguage -or $script:DisableSharedMailboxLogin -or $script:EnableSharedMailboxCopyToSent) {
    $Report += "<br><hr><h2>Exchange Online</h2>"
    $Report += checkMailboxReport -Language $script:SetMailboxLanguage
    $Report += checkSharedMailboxReport -Language $script:SetMailboxLanguage -DisableLogin $script:DisableSharedMailboxLogin -EnableCopy $script:EnableSharedMailboxCopyToSent
}

if ($script:ExoConnected -and (-not $KeepExoSessionAlive)) {
    disconnectExo
}

if ($script:GraphConnected -and (-not $KeepGraphSessionAlive)) {
    disconnectGraph
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
table {
    border-collapse: collapse;
    margin: 25px 0;
    font-size: 0.9em;
    font-family: sans-serif;
    min-width: 400px;
    box-shadow: 0 0 20px rgba(0, 0, 0, 0.15);
}
thead tr {
    color: #ffffff;
    text-align: left;
}
th,
td {
    padding: 12px 15px;
}
tbody tr {
    border-bottom: 1px solid #dddddd;
}
tbody tr:nth-of-type(even) {
    background-color: #f3f3f3;
}
</style>
"@

<# HTML report section #>
Write-Host "Generating HTML report"
$Report = ConvertTo-HTML -Body "$ReportTitleHtml $Report" -Title $ReportTitle -Head $Header -PostContent $PostContentHtml
$Report | Out-File $Desktop\AzureAdDeployer-Report.html
Invoke-Item $Desktop\AzureAdDeployer-Report.html
if ($script:InteractiveMode) { Read-Host "Click [ENTER] key to exit AzureAdDeployer" }