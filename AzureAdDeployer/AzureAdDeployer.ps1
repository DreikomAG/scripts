# Maintainer: https://github.com/swissbuechi
[CmdletBinding()]
Param(
    [switch]$Install,
    [switch]$UseExistingExoSession,   
    [switch]$KeepExoSessionAlive,    
    [switch]$UseExistingGraphSession,
    [switch]$KeepGraphSessionAlive,
    [switch]$AddExchangeOnlineReport,
    [switch]$CreateBreakGlassAccount
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
        User.Read.All, User.ReadWrite.All, Directory.Read.All, Directory.ReadWrite.All"
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

<# Security Defaults section #>
function checkSecurityDefaults {
    Write-Host "Checking Security Defaults"
    return (Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy -Property "isEnabled").IsEnabled
}

function checkSecurityDefaultsReport {
    param (
        [System.Boolean]$Fix
    )
    if (checkSecurityDefaults) {
        return "<br><h3>Security Defaults enabled</h3>"
    }
    #Todo: Enable / Disable Security Defaults
    return "<br><h3>Security Defaults disabled</h3>"
}

function updateSecurityDefaults {
    param ([System.Boolean]$enable)
    $params = @{
        IsEnabled = $enable
    }
    Write-Host "Updating Security Defaults"
    Update-MgPolicyIdentitySecurityDefaultEnforcementPolicy -BodyParameter $params
}

 <# BreakGlass account Section #>
function checkBreakGlassAccountReport {
    param (
        $Create
    )
    if ($BgAccount = getBreakGlassAccount) {
        return $BgAccount | ConvertTo-HTML -Property DisplayName, UserPrincipalName, GlobalAdmin -As Table -Fragment -PreContent "<h3>BreakGlass Account found</h3>"
    }
    #Todo: Create BG Account
    return "<h3>BreakGlass account not found</h3><p>Create account with <code> -CreateBreakGlassAccount </code></p>"
}

function getBreakGlassAccount {
    Write-Host "Checking BreakGlass account"
    $bgAccount = Get-MgUser -Filter "startswith(displayName,'BreakGlass ')" -Property Id, DisplayName, UserPrincipalName
    if (-not $bgAccount) { return }
    return [pscustomobject]@{
        DisplayName                       = $bgAccount.DisplayName
        UserPrincipalName                 = $bgAccount.UserPrincipalName
        GlobalAdmin                       = checkGlobalAdminRole $bgAccount.Id
    }
}

function checkGlobalAdminRole {
    param (
        $AccountId
    )
    Write-Host "Checking Global Admin Role"
    if (Get-MgDirectoryRoleMember -DirectoryRoleId "30436c3a-f5cd-467a-9b77-3267b1546b28" -Filter "id eq '$($AccountId)'") {
        return $true
    }
}

function creeateBreakGlassAccount {
    Write-Output "Creating BreakGlass Account:"
    $name = -join ((97..122) | Get-Random -Count 64 | % { [char]$_ })
    $pass = [System.Web.Security.Membership]::GeneratePassword(64, 4)
    $UPN = "$name@$MsDomain"
    
    Write-Output $UPN
    $DisplayName = "BreakGlass $name"
    Write-Output "Password:"
    Write-Output $pass
}

<# Conditional Access section #>
function getConditionalAccessPolicy {
    Write-Host "Checking Conditional Access policies"
    return Get-MgIdentityConditionalAccessPolicy -Property Id, DisplayName, State
}

function checkConditionalAccessPolicyReport {
    param (
        $Fix
    )
    if ($Policy = getConditionalAccessPolicy) {

        return $Policy | ConvertTo-HTML -Property DisplayName, Id, State -As Table -Fragment -PreContent "<br><h3>Conditional Access Policy found</h3>"
    }
    #Todo: Create BG Account
    return "<br><h3>Conditional Access Policy not found</h3>"
}
function deleteConditionalAccessPolicy {
    param (
        [Parameter(Mandatory = $true)]
        $Policies
    )
    foreach ($Policy in $Policies) {
        Write-Host "Removing existing Conditional Access policies"
        Remove-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $Policy.Id
    }
}

function cleanUpConditionalAccessPolicy {
    $Policies = getConditionalAccessPolicy
    deleteConditionalAccessPolicy $Policies
}

function getNamedLocations {
    return Get-MgIdentityConditionalAccessNamedLocation -Property Id, DisplayName
}

function createConditionalAccessPolicy {
    $params = @{
        DisplayName   = "Require MFA from all unknown locations"
        State         = "enabled"
        Conditions    = @{
            Applications = @{
                IncludeApplications = @(
                    "All"
                )
            }
            Users        = @{
                IncludeUsers = @(
                    "All"
                )
                ExcludeUsers = @(
                    getBreakGlassAccount.Id
                )
            }
            Locations    = @{
                IncludeLocations = @(
                    "All"
                )
                ExcludeLocations = @(
                    "AllTrusted"
                )
            }
        }
        GrantControls = @{
            Operator        = "OR"
            BuiltInControls = @(
                "mfa"
            )
        }
    }
    New-MgIdentityConditionalAccessPolicy -BodyParameter $params
}

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
    return [pscustomobject]@{
        DisplayName                       = $Mailbox.DisplayName
        UserPrincipalName                 = $Mailbox.UserPrincipalName
        Language                          = $ReginalConfig.Language
        TimeZone                          = $ReginalConfig.TimeZone
        MessageCopyForSentAsEnabled       = $Mailbox.MessageCopyForSentAsEnabled
        MessageCopyForSendOnBehalfEnabled = $Mailbox.MessageCopyForSendOnBehalfEnabled
        LoginAllowed                      = checkUserAccountStatus $Mailbox.UserPrincipalName
    }
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
    Write-Host "Installing prerequisite"
    installEXO
    installGraph
    return
}

if ($AddExchangeOnlineReport) { connectExo }
connectGraph

$Report = @()

$Report += "<br><h2>Azure Active Directory security settings</h2>"
$Report += checkBreakGlassAccountReport -Create $CreateBreakGlassAccount
$Report += checkSecurityDefaultsReport -Fix $false
$Report += checkConditionalAccessPolicyReport -Fix $false

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