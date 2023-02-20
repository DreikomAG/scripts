<#
=============================================================================================
Name:           AzureAdDeployer
Description:    This script generates a HTML report for AAD, SPO, EXO
Website:        https://github.com/DreikomAG/scripts/tree/main/AzureAdDeployer
Script by:      https://github.com/swissbuechi
============================================================================================
#>
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
    [switch]$DisableUsersToCreateAppRegistrations,
    [switch]$DisableUsersToReadOtherUsers,
    [switch]$DisableUsersToCreateSecurityGroups,
    [switch]$EnableBlockMsolPowerShell,
    [switch]$SetMailboxLanguage,
    [switch]$DisableSharedMailboxLogin,
    [switch]$EnableSharedMailboxCopyToSent,
    [switch]$HideUnifiedMailboxFromOutlookClient,
    [switch]$DisableAddToOneDrive
)
$ReportTitle = "Microsoft 365 Security Report"
$Version = "2.11.2"
$VersionMessage = "AzureAdDeployer version: $($Version)"

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
$script:DisableUsersToCreateAppRegistrations = $DisableUsersToCreateAppRegistrations
$script:DisableUsersToReadOtherUsers = $DisableUsersToReadOtherUsers
$script:DisableUsersToCreateSecurityGroups = $DisableUsersToCreateSecurityGroups
$script:EnableBlockMsolPowerShell = $EnableBlockMsolPowerShell

$script:SetMailboxLanguage = $SetMailboxLanguage
$script:DisableSharedMailboxLogin = $DisableSharedMailboxLogin
$script:EnableSharedMailboxCopyToSent = $EnableSharedMailboxCopyToSent
$script:HideUnifiedMailboxFromOutlookClient = $HideUnifiedMailboxFromOutlookClient

$script:DisableAddToOneDrive = $DisableAddToOneDrive

$script:AddExchangeOnlineReport = $AddExchangeOnlineReport
$script:AddSharePointOnlineReport = $AddSharePointOnlineReport

Write-Host $VersionMessage

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
    $script:AddExchangeOnlineReport = $true
    $script:AddSharePointOnlineReport = $true
    mainMenu
}
function mainMenu {
    $StartOptionValue = 0
    while (($result -ne $StartOptionValue) -or ($result -ne 1)) {
        $Status = @"

Main menu:
S: Start
C: Configure options
1: Add SharePoint Online report: $($script:AddSharePointOnlineReport)
2: Add Exchange Online report: $($script:AddExchangeOnlineReport)
"@
        $StartOption = New-Object System.Management.Automation.Host.ChoiceDescription "&START", "Start"
        $ConfigureOption = New-Object System.Management.Automation.Host.ChoiceDescription "&CONFIGURE", "Add SharePoint Online report"
        $AddSharePointOnlineReportOption = New-Object System.Management.Automation.Host.ChoiceDescription "&1 SPO", "Add SharePoint Online report"
        $AddExchangeOnlineReportOption = New-Object System.Management.Automation.Host.ChoiceDescription "&2 EXO", "Add Exchange Online report"
        $Options = [System.Management.Automation.Host.ChoiceDescription[]]($StartOption, $ConfigureOption, $AddSharePointOnlineReportOption, $AddExchangeOnlineReportOption )
        Write-Host $Status
        $result = $host.ui.PromptForChoice("", "", $Options, $StartOptionValue)
        switch ($result) {
            0 { return }
            1 { configMenu }
            2 { $script:AddSharePointOnlineReport = ! $script:AddSharePointOnlineReport }
            3 { $script:AddExchangeOnlineReport = ! $script:AddExchangeOnlineReport }
        }
    }
}
function configMenu {
    $StartOptionValue = 0
    
    $Status = @"

Configure menu:
1: Azure Active Directory
2: SharePoint Online
3: Exchange Online
B: Back to main menu
"@
    $BackOption = New-Object System.Management.Automation.Host.ChoiceDescription "&BACK", "Back to main menu"
    $AADOption = New-Object System.Management.Automation.Host.ChoiceDescription "&1 AAD", "Azure Active Directory options"
    $SPOOption = New-Object System.Management.Automation.Host.ChoiceDescription "&2 SPO", "SharePoint Online options"
    $EXOOption = New-Object System.Management.Automation.Host.ChoiceDescription "&3 EXO", "Exchange Online options"
    $Options = [System.Management.Automation.Host.ChoiceDescription[]]($BackOption, $AADOption, $SPOOption, $EXOOption)
    Write-Host $Status
    $result = $host.ui.PromptForChoice("", "", $Options, $StartOptionValue)
    switch ($result) {
        0 { return }
        1 { AADMenu }
        2 { SPOMenu }
        3 { EXOMenu }
    }
}
function AADMenu {
    $StartOptionValue = 0
    while ($result -ne $StartOptionValue) {
        $Status = @"

Azure Active Directory options:
1: Create BreakGlass account: $($script:CreateBreakGlassAccount)
2: Enable Security Defaults: $($script:EnableSecurityDefaults)
3: Disable Security Defaults: $($script:DisableSecurityDefaults)
4: Disable Enterprise Application user consent: $($script:DisableEnterpiseApplicationUserConsent)
5: Disable user to create app registrations: $($script:DisableUsersToCreateAppRegistrations)
6: Disable user to read other users: $($script:DisableUsersToReadOtherUsers)
7: Disable users to create security groups: $($script:DisableUsersToCreateSecurityGroups)
8: Disable legacy MsolPowerShell access: $($script:EnableBlockMsolPowerShell)
B: Back to main menu
"@
        $BackOption = New-Object System.Management.Automation.Host.ChoiceDescription "&BACK", "Back to main menu"
        $CreateBreakGlassAccountOption = New-Object System.Management.Automation.Host.ChoiceDescription "&1", "Create BreakGlass account"
        $EnableSecurityDefaultsOption = New-Object System.Management.Automation.Host.ChoiceDescription "&2", "Enable Security Defaults"
        $DisableSecurityDefaultsOption = New-Object System.Management.Automation.Host.ChoiceDescription "&3", "Disable Security Defaults"
        $DisableEnterpiseApplicationUserConsentOption = New-Object System.Management.Automation.Host.ChoiceDescription "&4", "Disable Enterprise Application user consent"
        $DisableUsersToCreateAppRegistrationsOption = New-Object System.Management.Automation.Host.ChoiceDescription "&5", "Disable user to create app registrations"
        $DisableUsersToReadOtherUsersOption = New-Object System.Management.Automation.Host.ChoiceDescription "&6", "Disable user to read other users"
        $DisableUsersToCreateSecurityGroupsOption = New-Object System.Management.Automation.Host.ChoiceDescription "&7", "Disable users to create security groups"
        $EnableBlockMsolPowerShellOption = New-Object System.Management.Automation.Host.ChoiceDescription "&8", "Disable legacy MsolPowerShell access"

        $Options = [System.Management.Automation.Host.ChoiceDescription[]]($BackOption, $CreateBreakGlassAccountOption, $EnableSecurityDefaultsOption, $DisableSecurityDefaultsOption, $DisableEnterpiseApplicationUserConsentOption, $DisableUsersToCreateAppRegistrationsOption, $DisableUsersToReadOtherUsersOption, $DisableUsersToCreateSecurityGroupsOption, $EnableBlockMsolPowerShellOption)
        Write-Host $Status
        $result = $host.ui.PromptForChoice("", "", $Options, $StartOptionValue)
        switch ($result) {
            0 { return }
            1 { $script:CreateBreakGlassAccount = ! $script:CreateBreakGlassAccount }
            2 { $script:EnableSecurityDefaults = ! $script:EnableSecurityDefaults }
            3 { $script:DisableSecurityDefaults = ! $script:DisableSecurityDefaults }
            4 { $script:DisableEnterpiseApplicationUserConsent = ! $script:DisableEnterpiseApplicationUserConsent }
            5 { $script:DisableUsersToCreateAppRegistrations = ! $script:DisableUsersToCreateAppRegistrations }
            6 { $script:DisableUsersToReadOtherUsers = ! $script:DisableUsersToReadOtherUsers }
            7 { $script:DisableUsersToCreateSecurityGroups = ! $script:DisableUsersToCreateSecurityGroups }
            8 { $script:EnableBlockMsolPowerShell = ! $script:EnableBlockMsolPowerShell }
        }
    }
}
function SPOMenu {
    $StartOptionValue = 0
    while ($result -ne $StartOptionValue) {
        $Status = @"

SharePoint Online options:
1: Disable add to OneDrive button: $($script:DisableAddToOneDrive)
B: Back to main menu
"@
        $BackOption = New-Object System.Management.Automation.Host.ChoiceDescription "&BACK", "Back to main menu"
        $DisableAddToOneDriveOption = New-Object System.Management.Automation.Host.ChoiceDescription "&1}", "Disable add to OneDrive button"
        $Options = [System.Management.Automation.Host.ChoiceDescription[]]($BackOption, $DisableAddToOneDriveOption)
        Write-Host $Status
        $result = $host.ui.PromptForChoice("", "", $Options, $StartOptionValue)
        switch ($result) {
            0 { return }
            1 { $script:DisableAddToOneDrive = ! $script:DisableAddToOneDrive }
        }
    }
}
function EXOMenu {
    $StartOptionValue = 0
    while ($result -ne $StartOptionValue) {
        $Status = @"

Exchange Online options:
1: Set mailbox language: $($script:SetMailboxLanguage)
2: Disable shared mailbox login: $($script:DisableSharedMailboxLogin)
3: Enable shared mailbox copy to sent: $($script:EnableSharedMailboxCopyToSent)
4: Hide unified mailbox from outlook client: $($script:HideUnifiedMailboxFromOutlookClient)
B: Back to main menu
"@
        $BackOption = New-Object System.Management.Automation.Host.ChoiceDescription "&BACK", "Back to main menu"
        $SetMailboxLanguageOption = New-Object System.Management.Automation.Host.ChoiceDescription "&1", "Set mailbox language"
        $DisableSharedMailboxLoginOption = New-Object System.Management.Automation.Host.ChoiceDescription "&2", "Disable shared mailbox login"
        $EnableSharedMailboxCopyToSentOption = New-Object System.Management.Automation.Host.ChoiceDescription "&3", "Enable shared mailbox copy to sent"
        $HideUnifiedMailboxFromOutlookClientOption = New-Object System.Management.Automation.Host.ChoiceDescription "&4", "Hide unified mailbox from outlook client"

        $Options = [System.Management.Automation.Host.ChoiceDescription[]]($BackOption, $SetMailboxLanguageOption, $DisableSharedMailboxLoginOption, $EnableSharedMailboxCopyToSentOption, $HideUnifiedMailboxFromOutlookClientOption)
        Write-Host $Status
        $result = $host.ui.PromptForChoice("", "", $Options, $StartOptionValue)
        switch ($result) {
            0 { return }
            1 { $script:SetMailboxLanguage = ! $script:SetMailboxLanguage }
            2 { $script:DisableSharedMailboxLogin = ! $script:DisableSharedMailboxLogin }
            3 { $script:EnableSharedMailboxCopyToSent = ! $script:EnableSharedMailboxCopyToSent }
            4 { $script:HideUnifiedMailboxFromOutlookClient = ! $script:HideUnifiedMailboxFromOutlookClient }
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
Policy.ReadWrite.Authorization, Sites.Read.All, AuditLog.Read.All, UserAuthenticationMethod.Read.All, Organization.Read.All" | Out-Null
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
        Write-Host "Connected to Exchange Online PowerShell using $((Get-ConnectionInformation).UserPrincipalName) account"
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

<# Tenant user settings policy section #>
function checkTenanUserSettingsReport {
    param(
        [System.Boolean]$DisableUserConsent,
        [System.Boolean]$DisableUsersToCreateAppRegistrations,
        [System.Boolean]$DisableUsersToReadOtherUsers,
        [System.Boolean]$DisableUsersToCreateSecurityGroups,
        [System.Boolean]$EnableBlockMsolPowerShell
    )
    if ($DisableUserConsent) { disableApplicationUserConsent }
    if ($DisableUsersToCreateAppRegistrations) { disableUsersToCreateAppRegistrations }
    if ($DisableUsersToReadOtherUsers) { disableUsersToReadOtherUsers }
    if ($DisableUsersToCreateSecurityGroups) { disableUsersToCreateSecurityGroups }
    if ($EnableBlockMsolPowerShell) { enableBlockMsolPowerShell }
    Write-Host "Checking tenant user settings"
    $Policy = Get-MgPolicyAuthorizationPolicy -Property BlockMsolPowerShell, DefaultUserRolePermissions
    $Report = $Policy | Select-Object -Property  @{Name = "PermissionGrantPoliciesAssigned"; Expression = { [string]$_.DefaultUserRolePermissions.PermissionGrantPoliciesAssigned } },
    @{Name = "AllowedToCreateApps"; Expression = { [string]$_.DefaultUserRolePermissions.AllowedToCreateApps } },
    @{Name = "AllowedToCreateSecurityGroups"; Expression = { [string]$_.DefaultUserRolePermissions.AllowedToCreateSecurityGroups } },
    @{Name = "AllowedToReadOtherUsers"; Expression = { [string]$_.DefaultUserRolePermissions.AllowedToReadOtherUsers } }, BlockMsolPowerShell | ConvertTo-Html -As List -Fragment -PreContent "<h3 id='AAD_USER_SETTINGS'>Tenant user settings</h3>" -PostContent "<p>PermissionGrantPoliciesAssigned: empty (user consent not allowed), microsoft-user-default-legacy (user consent allowed for all apps), microsoft-user-default-low (user consent allowed for low permission apps)</p>"
    $Report = $Report -Replace "<td>PermissionGrantPoliciesAssigned:</td><td>ManagePermissionGrantsForSelf.microsoft-user-default-legacy</td>", "<td>PermissionGrantPoliciesAssigned:</td><td class='red'>microsoft-user-default-legacy</td>"
    $Report = $Report -Replace "<td>PermissionGrantPoliciesAssigned:</td><td>ManagePermissionGrantsForSelf.microsoft-user-default-low</td>", "<td>PermissionGrantPoliciesAssigned:</td><td class='orange'>microsoft-user-default-low</td>"
    $Report = $Report -Replace "<td>AllowedToCreateApps:</td><td>True</td>", "<td>AllowedToCreateApps:</td><td class='red'>True</td>"
    $Report = $Report -Replace "<td>AllowedToCreateSecurityGroups:</td><td>True</td>", "<td>AllowedToCreateSecurityGroups:</td><td class='red'>True</td>"
    $Report = $Report -Replace "<td>AllowedToReadOtherUsers:</td><td>True</td>", "<td>AllowedToReadOtherUsers:</td><td class='red'>True</td>"
    $Report = $Report -Replace "<td>BlockMsolPowerShell:</td><td>False</td>", "<td>BlockMsolPowerShell:</td><td class='red'>False</td>"
    return $Report
}
function disableApplicationUserConsent {
    Write-Host "Disable Enterprise Application user consent"
    Update-MgPolicyAuthorizationPolicy -DefaultUserRolePermissions @{ "PermissionGrantPoliciesAssigned" = @() }
}
function disableUsersToCreateAppRegistrations {
    Write-Host "Disable user to create app registrations"
    Update-MgPolicyAuthorizationPolicy -DefaultUserRolePermissions @{ "AllowedToCreateApps" = $false }
}
function disableUsersToReadOtherUsers {
    Write-Host "Disable user to read other users"
    Update-MgPolicyAuthorizationPolicy -DefaultUserRolePermissions @{ "AllowedToReadOtherUsers" = $false }
}
function disableUsersToCreateSecurityGroups {
    Write-Host "Disable users to create security groups"
    Update-MgPolicyAuthorizationPolicy -DefaultUserRolePermissions @{ "AllowedToCreateSecurityGroups" = $false }
}
function enableBlockMsolPowerShell {
    Write-Host "Disable legacy MsolPowerShell access"
    Update-MgPolicyAuthorizationPolicy -BlockMsolPowerShell
}

<# TODO: Tenant group settings policy #>
function checkTenantGroupSettingsReport {
    param(
        [System.Boolean]$DisableUsersToCreateUnifiedGroups
    )
    Write-Host "Checking group settings"
    $GroupSettingTemplates = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groupSettingTemplates?$select=id,displayName"
    $GroupSettingTemplateUnified = $GroupSettingTemplates.value | Where-Object { $_.displayName -eq "Group.Unified" } | Select-Object -Property id, DisplayName

    $GroupSettings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groupSettings?$select=value" 
    $GroupSettingUnified = $GroupSettings.value | Where-Object { $_.templateId -eq $GroupSettingTemplateUnified.id } | Select-Object -Property id, templateId, values

    if ($DisableUsersToCreateUnifiedGroups) {
        if ($GroupSettingUnified) { disableUnifiedGroupCreation -GroupSettingTemplateUnified $GroupSettingTemplateUnified -GroupSettingUnified $GroupSettingUnified }  
        else { disableUnifiedGroupCreation -GroupSettingTemplateUnified $GroupSettingTemplateUnified }
    }
}

function disableUnifiedGroupCreation {
    param(
        $GroupSettingTemplateUnified,
        $GroupSettingUnified
    )
    $Body = @{
        templateId = $GroupSettingTemplateUnified.id
        values     = @( @{ Name = "EnableGroupCreation" ; Value = "false" } )
    }
    if ($GroupSettingUnified) { Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/groupSettings/$($GroupSettingUnified.id)" -Body $Body }
    else { Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/groupSettings" -Body $Body }
}

<# License SKU section#>
function checkUsedSKUReport {
    Write-Host "Checking licenses"
    $SKU = Get-MgSubscribedSku -Property SkuPartNumber, ConsumedUnits, PrepaidUnits, AppliesTo
    return $SKU | Select-Object -Property @{Name = "Name"; Expression = { 
            if ($_.SkuPartNumber -eq "EXCHANGESTANDARD") { return "Exchange Online (Plan 1)" }
            if ($_.SkuPartNumber -eq "EXCHANGEENTERPRISE") { return "Exchange Online (PLAN 2)" }
            if ($_.SkuPartNumber -eq "EXCHANGEARCHIVE_ADDON") { return "Exchange Online Archiving for Exchange Online" }
            if ($_.SkuPartNumber -eq "EXCHANGE_S_ESSENTIALS") { return "Exchange Online Essentials" }

            if ($_.SkuPartNumber -eq "SHAREPOINTSTANDARD") { return "SharePoint Online (Plan 1)" }
            if ($_.SkuPartNumber -eq "SHAREPOINTENTERPRISE") { return "SharePoint Online (Plan 2)" }

            if ($_.SkuPartNumber -eq "AAD_BASIC") { return "Azure Active Directory Basic" }
            if ($_.SkuPartNumber -eq "AAD_PREMIUM") { return "Azure Active Directory Premium P1" }
            if ($_.SkuPartNumber -eq "AAD_PREMIUM_P2") { return "Azure Active Directory Premium P2" }

            if ($_.SkuPartNumber -eq "EMS") { return "Enterprise Mobility + Security E3" }
            if ($_.SkuPartNumber -eq "EMSPREMIUM") { return "Enterprise Mobility + Security E5" }

            if ($_.SkuPartNumber -eq "INTUNE_A") { return "Intune" }
            if ($_.SkuPartNumber -eq "INTUNE_A_D") { return "Microsoft Intune Device" }
            if ($_.SkuPartNumber -eq "INTUNE_SMB") { return "Microsoft Intune SMB" }

            if ($_.SkuPartNumber -eq "WINDOWS_STORE") { return "Windows Store for Business" }
            if ($_.SkuPartNumber -eq "RMSBASIC") { return "Rights Management Service Basic Content Protection" }
            if ($_.SkuPartNumber -eq "RIGHTSMANAGEMENT_ADHOC") { return "Rights Management Adhoc" }

            if ($_.SkuPartNumber -eq "VISIO_PLAN1_DEPT") { return "Visio Plan 1" }
            if ($_.SkuPartNumber -eq "VISIO_PLAN2_DEPT	") { return "Visio Plan 2" }
            if ($_.SkuPartNumber -eq "VISIOONLINE_PLAN1") { return "Visio Online Plan 1" }
            if ($_.SkuPartNumber -eq "VISIOCLIENT") { return "Visio Online Plan 2" }

            if ($_.SkuPartNumber -eq "PROJECTESSENTIALS") { return "Project Online Essentials" }
            if ($_.SkuPartNumber -eq "PROJECTPREMIUM") { return "Project Online Premium" }
            if ($_.SkuPartNumber -eq "PROJECT_P1") { return "Project Plan 1" }
            if ($_.SkuPartNumber -eq "PROJECTPROFESSIONAL") { return "Project Plan 3" }

            if ($_.SkuPartNumber -eq "MS_TEAMS_IW") { return "Microsoft Teams Trial" }
            if ($_.SkuPartNumber -eq "MCOCAP") { return "Microsoft Teams Shared Devices" }
            if ($_.SkuPartNumber -eq "MCOEV") { return "Microsoft Teams Phone Standard" }
            if ($_.SkuPartNumber -eq "MCOEV_DOD") { return "Microsoft Teams Phone Standard for DOD" }
            if ($_.SkuPartNumber -eq "MCOTEAMS_ESSENTIALS") { return "Teams Phone with Calling Plan" }
            if ($_.SkuPartNumber -eq "TEAMS_FREE") { return "Microsoft Teams (Free)" }
            if ($_.SkuPartNumber -eq "Teams_Ess") { return "Microsoft Teams Essentials" }
            if ($_.SkuPartNumber -eq "Microsoft_Teams_Premium") { return "Microsoft Teams Premium" }
            if ($_.SkuPartNumber -eq "TEAMS_EXPLORATORY") { return "Microsoft Teams Exploratory" }
            if ($_.SkuPartNumber -eq "BUSINESS_VOICE_DIRECTROUTING") { return "Microsoft 365 Business Voice (without calling plan)" }
            if ($_.SkuPartNumber -eq "PHONESYSTEM_VIRTUALUSER") { return "Microsoft Teams Phone Resoure Account" }
            if ($_.SkuPartNumber -eq "Microsoft_Teams_Rooms_Basic_without_Audio_Conferencing") { return "Microsoft Teams Rooms Basic without Audio Conferencing" }
            if ($_.SkuPartNumber -eq "Microsoft_Teams_Rooms_Pro") { return "Microsoft Teams Rooms Pro" }
            if ($_.SkuPartNumber -eq "BUSINESS_VOICE_MED2") { return "Microsoft 365 Business Voice" }
            if ($_.SkuPartNumber -eq "MCOPSTN_5") { return "Microsoft 365 Domestic Calling Plan (120 Minutes)" }

            if ($_.SkuPartNumber -eq "POWER_BI_PRO") { return "Power BI Pro" }
            if ($_.SkuPartNumber -eq "POWERAPPS_VIRAL") { return "Microsoft Power Apps Plan 2 Trial" }
            if ($_.SkuPartNumber -eq "SPZA_IW") { return "App Connect IW" }
            if ($_.SkuPartNumber -eq "FLOW_FREE") { return "Microsoft Flow Free" }
            if ($_.SkuPartNumber -eq "CCIBOTS_PRIVPREV_VIRAL") { return "Power Virtual Agents Viral Trial" }
            if ($_.SkuPartNumber -eq "VIRTUAL_AGENT_BASE") { return "Power Virtual Agent" }

            if ($_.SkuPartNumber -eq "WIN_DEF_ATP") { return "Microsoft Defender for Endpoint" }
            if ($_.SkuPartNumber -eq "ADALLOM_STANDALONE") { return "Microsoft Cloud App Security" }
            if ($_.SkuPartNumber -eq "DEFENDER_ENDPOINT_P1") { return "Microsoft Defender for Endpoint P1" }
            if ($_.SkuPartNumber -eq "MDATP_Server") { return "Microsoft Defender for Endpoint Server" }
            if ($_.SkuPartNumber -eq "ATP_ENTERPRISE_FACULTY") { return "Microsoft Defender for Office 365 (Plan 1) Faculty" }
            if ($_.SkuPartNumber -eq "ATA") { return "Microsoft Defender for Identity" }
            if ($_.SkuPartNumber -eq "ATP_ENTERPRISE") { return "Microsoft Defender for Office 365 (Plan 1)" }

            if ($_.SkuPartNumber -eq "M365_F1") { return "Microsoft 365 F1" }
            if ($_.SkuPartNumber -eq "SPE_F1") { return "Microsoft 365 F3" }
            if ($_.SkuPartNumber -eq "DESKLESSPACK") { return "Office 365 F3" }

            if ($_.SkuPartNumber -eq "SPE_E3") { return "Microsoft 365 E3" }
            if ($_.SkuPartNumber -eq "SPE_E5") { return "Microsoft 365 E5" }
            if ($_.SkuPartNumber -eq "SPE_E5_CALLINGMINUTES") { return "Microsoft 365 E5 with Calling Minutes" }
            if ($_.SkuPartNumber -eq "INFORMATION_PROTECTION_COMPLIANCE") { return "Microsoft 365 E5 Compliance" }
            if ($_.SkuPartNumber -eq "IDENTITY_THREAT_PROTECTION") { return "Microsoft 365 E5 Security" }
            if ($_.SkuPartNumber -eq "SPE_E5_NOPSTNCONF") { return "Microsoft 365 E5 without Audio Conferencing" }
            
            if ($_.SkuPartNumber -eq "STANDARDPACK") { return "Office 365 E1" }
            if ($_.SkuPartNumber -eq "STANDARDWOFFPACK") { return "Office 365 E2" }
            if ($_.SkuPartNumber -eq "ENTERPRISEPACK") { return "Office 365 E3" }
            if ($_.SkuPartNumber -eq "ENTERPRISEWITHSCAL") { return "Office 365 E4" }
            if ($_.SkuPartNumber -eq "ENTERPRISEPREMIUM") { return "Office 365 E5" }
            if ($_.SkuPartNumber -eq "ENTERPRISEPREMIUM_NOPSTNCONF") { return "Office 365 E5 without Audio Conferencing" }

            if ($_.SkuPartNumber -eq "SPB") { return "Microsoft 365 Business Premium" }
            if ($_.SkuPartNumber -eq "O365_BUSINESS_PREMIUM") { return "Microsoft 365 Business Standard" }
            if (($_.SkuPartNumber -eq "O365_BUSINESS") -or ($_.SkuPartNumber -eq "SMB_BUSINESS")) { return "Microsoft 365 Apps for Business" }
            if ($_.SkuPartNumber -eq "OFFICESUBSCRIPTION") { return "Microsoft 365 Apps for enterprise" }
            if (($_.SkuPartNumber -eq "O365_BUSINESS_ESSENTIALS") -or ($_.SkuPartNumber -eq "SMB_BUSINESS_ESSENTIALS")) { return "Microsoft 365 Business Basic" }
            else { return $_.SkuPartNumber }
        } 
    }, @{Name = "Total"; Expression = { $_.PrepaidUnits.Enabled } }, @{Name = "Assigned"; Expression = { $_.ConsumedUnits } } , @{Name = "Available"; Expression = { ($_.PrepaidUnits.Enabled) - ($_.ConsumedUnits) } } , AppliesTo | ConvertTo-Html -As Table -Fragment -PreContent "<br><h3 id='AAD_SKU'>Licenses</h3>"
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
    return $Assignments | Where-Object { -not ($null -eq $_.DisplayName) } | Sort-Object -Property UserPrincipalName | ConvertTo-HTML -Property DisplayName, UserPrincipalName, RoleName -As Table -Fragment -PreContent "<br><h3 id='AAD_ADMINS'>Admin role assignments</h3>"
}

<# BreakGlass account Section #>
function checkBreakGlassAccountReport {
    param (
        $Create
    )
    if ($BgAccount = getBreakGlassAccount) {
        $Report = $BgAccount | ConvertTo-HTML -Property DisplayName, UserPrincipalName, AccountEnabled, GlobalAdmin, LastSignIn -As Table -Fragment -PreContent "<br><h3 id='AAD_BG'>BreakGlass account</h3>"
        $Report = $Report -Replace "<td>False</td>", "<td class='red'>False</td>"
        return $Report

    }
    if ($create) {
        createBreakGlassAccount
        $Report = getBreakGlassAccount | ConvertTo-HTML -Property DisplayName, UserPrincipalName, AccountEnabled, GlobalAdmin, LastSignIn -As Table -Fragment -PreContent "<br><h3 id='AAD_BG'>BreakGlass account</h3>" -PostContent "<p>Check console log for credentials</p>"
        $Report = $Report -Replace "<td>False</td>", "<td class='red'>False</td>"
        return $Report
    }
    return "<br><h3 id='AAD_BG'>BreakGlass account</h3><p>Not found</p>"
}
function getBreakGlassAccount {
    Write-Host "Checking BreakGlass account"
    Select-MgProfile -Name "beta"
    $BgAccounts = Get-MgUser -Filter "startswith(displayName, 'BreakGlass ')" -Property Id, DisplayName, UserPrincipalName, AccountEnabled, SignInActivity
    Select-MgProfile -Name "v1.0"
    if (-not $bgAccounts) { 
        $BgAccounts = Get-MgUser -Filter "startswith(displayName, 'BreakGlass ')" -Property Id, DisplayName, UserPrincipalName, AccountEnabled
    }
    if (-not $bgAccounts) { return }
    foreach ($BgAccount in $BgAccounts) {
        Add-Member -InputObject $BgAccount -NotePropertyName "GlobalAdmin" -NotePropertyValue (checkGlobalAdminRole $BgAccount.Id)
        Add-Member -InputObject $BgAccount -NotePropertyName "LastSignIn" -NotePropertyValue $BgAccount.SignInActivity.LastSignInDateTime
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
    $Users = Get-MgUser -All -Filter "UserType eq 'Member'" -Property Id, DisplayName, UserPrincipalName, AssignedLicenses, AccountEnabled
    $Users | ForEach-Object {
        $ProcessedCount++
        if (($_.AssignedLicenses).Count -ne 0) {
            $LicenseStatus = "Licensed"
        }
        else {
            $LicenseStatus = "Unlicensed"
        }
        Write-Progress -Activity "Processed count: $ProcessedCount; Currently processing: $($_.DisplayName)"
        [array]$MFAData = Get-MgUserAuthenticationMethod -UserId $_.Id
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
        [array]$StrongMFAMethods = ("Fido2", "PasswordlessMSAuthenticator", "AuthenticatorApp", "WindowsHelloForBusiness", "SoftwareOath")
        $MFAStatus = "Disabled"
        foreach ($StrongMFAMethod in $StrongMFAMethods) {
            if ($AuthenticationMethod -contains $StrongMFAMethod) {
                $MFAStatus = "Strong"
                break
            }
        }
        if ( ($AuthenticationMethod -contains "PhoneAuthentication") -or ($AuthenticationMethod -contains "EmailAuthentication")) {
            $MFAStatus = "Weak"
        }
        Add-Member -InputObject $_ -NotePropertyName "LicenseStatus" -NotePropertyValue $LicenseStatus
        Add-Member -InputObject $_ -NotePropertyName "MFAStatus" -NotePropertyValue $MFAStatus
        Add-Member -InputObject $_ -NotePropertyName "AdditionalDetail" -NotePropertyValue $AdditionalDetail
    }
    Write-Progress -Activity "Processed count: $ProcessedCount; Currently processing: $($_.DisplayName)" -Status "Ready" -Completed
    $Report = $Users | Sort-Object -Property UserPrincipalName | ConvertTo-HTML -Property DisplayName, UserPrincipalName, LicenseStatus, AccountEnabled, MFAStatus, AdditionalDetail -As Table -Fragment -PreContent "<br><h3 id='AAD_MFA'>User MFA status</h3>" -PostContent "<p>Weak: PhoneAuthentication, EmailAuthentication</p><p>Strong: Fido2, PasswordlessMSAuthenticator, AuthenticatorApp, WindowsHelloForBusiness, SoftwareOath</p>"
    $Report = $Report -Replace "<td>True</td><td>Disabled</td>", "<td>True</td><td class='red'>Disabled</td>"
    $Report = $Report -Replace "<td>True</td><td>Weak</td>", "<td>True</td><td class='orange'>Weak</td>"
    return $Report
}

<# Guest user section#>
function checkGuestUserReport {
    Write-Host "Checking guest accounts"
    Select-MgProfile -Name "beta"
    $Users = Get-MgUser -All -Filter "UserType eq 'Guest'" -Property Id, DisplayName, UserPrincipalName, AccountEnabled, SignInActivity
    Select-MgProfile -Name "v1.0"
    if (-not $Users) {
        return "<br><h3 id='AAD_GUEST'>Guest accounts</h3><p>Not found</p>"
    }
    return $Users | Select-Object -Property DisplayName, UserPrincipalName, AccountEnabled, @{Name = "LastSignIn"; Expression = { $_.SignInActivity.LastSignInDateTime } } | Sort-Object -Property LastSignIn | ConvertTo-HTML -As Table -Fragment -PreContent "<br><h3 id='AAD_GUEST'>Guest accounts</h3>"
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
        return "<br><h3 id='AAD_SEC_DEFAULTS'>Security Defaults</h3><p>Enabled</p>"
    }
    return "<br><h3 id='AAD_SEC_DEFAULTS'>Security Defaults</h3><p>Disabled</p>"
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
function checkConditionalAccessPolicyReport {
    Write-Host "Checking Conditional Access policies"
    if ($Policy = Get-MgIdentityConditionalAccessPolicy -Property Id, DisplayName, State) {
        return $Policy | ConvertTo-HTML -Property DisplayName, Id, State -As Table -Fragment -PreContent "<br><h3 id='AAD_CA'>Conditional Access policies</h3>"
    }
    return "<br><h3 id='AAD_CA'>Conditional Access policies</h3><p>Not found</p>"
}
function checkNamedLocationReport {
    Write-Host "Checking named locations"
    if ($Locations = Get-MgIdentityConditionalAccessNamedLocation) {
        return $Locations | Select-Object -Property DisplayName, @{Name = "Trusted"; Expression = { $_.additionalProperties["isTrusted"] } }, @{Name = "IPRange"; Expression = {
                $IpRangesReport = @()
                foreach ($IpRange in ($_.additionalProperties["ipRanges"])) {
                    $IpRangesReport += $IpRange["cidrAddress"]
                }
                return $IpRangesReport
            }
        }, @{Name = "Countries"; Expression = { $_.additionalProperties["countriesAndRegions"] } } | ConvertTo-HTML -As Table -Fragment -PreContent "<br><h3 id='AAD_CA_LOCATIONS'>Named locations</h3>"
    }
    return "<br><h3 id='AAD_CA_LOCATIONS'>Named locations</h3><p>Not found</p>"
}

<# Application protection polices section#>
function checkAppProtectionPolicesReport {
    Write-Host "Checking App protection policies"
    if ($Polices = getAppProtectionPolices) {
        return $Polices | ConvertTo-HTML -As Table -Property DisplayName, IsAssigned -Fragment -PreContent "<br><h3 id='AAD_APP_POLICY'>App protection policies</h3>"
    }
    return "<br><h3 id='AAD_APP_POLICY'>App protection policies</h3><p>Not found</p>"
}
function getAppProtectionPolices {
    $IOSPolicies = Get-MgDeviceAppManagementiOSManagedAppProtection -Property DisplayName, IsAssigned
    $AndroidPolicies = Get-MgDeviceAppManagementAndroidManagedAppProtection -Property DisplayName, IsAssigned
    $Policies = @()
    $Policies += $IOSPolicies
    $Policies += $AndroidPolicies
    return $Policies
}

<# SharePoint Tenant section #>
function checkSpoTenantReport {
    param(
        [System.Boolean]$DisableAddToOneDrive
    )
    Write-Host "Checking SharePoint Online tenant"
    if ($DisableAddToOneDrive) {
        Write-Host "Disable add to OneDrive button"
        Set-PnPTenant -DisableAddToOneDrive $True
    }
    $Report = Get-PnPTenant | ConvertTo-HTML -As List -Property LegacyAuthProtocolsEnabled, DisableAddToOneDrive, ConditionalAccessPolicy, SharingCapability, ODBMembersCanShare, PreventExternalUsersFromResharing, DefaultSharingLinkType, DefaultLinkPermission, FolderAnonymousLinkType, FileAnonymousLinkType, RequireAnonymousLinksExpireInDays -Fragment -PreContent "<h3 id='SPO_SETTINGS'>Tenant settings</h3>" -PostContent "<p>ConditionalAccessPolicy: AllowFullAccess, AllowLimitedAccess, BlockAccess</p>
    <p>SharingCapability: Disabled, ExternalUserSharingOnly, ExternalUserAndGuestSharing, ExistingExternalUserSharingOnly</p>
    <p>DefaultSharingLinkType: None, Direct, Internal, AnonymousAccess</p>"
    $Report = $Report -Replace "<td>LegacyAuthProtocolsEnabled:</td><td>True</td>", "<td>LegacyAuthProtocolsEnabled:</td><td class='red'>True</td>"
    $Report = $Report -Replace "<td>DisableAddToOneDrive:</td><td>False</td>", "<td>DisableAddToOneDrive:</td><td class='red'>False</td>"
    $Report = $Report -Replace "<td>ConditionalAccessPolicy:</td><td>AllowFullAccess</td>", "<td>ConditionalAccessPolicy:</td><td class='red'>AllowFullAccess</td>"
    $Report = $Report -Replace "<td>SharingCapability:</td><td>ExternalUserAndGuestSharing</td>", "<td>SharingCapability:</td><td class='red'>ExternalUserAndGuestSharing</td>"
    $Report = $Report -Replace "<td>PreventExternalUsersFromResharing:</td><td>False</td>", "<td>PreventExternalUsersFromResharing:</td><td class='red'>False</td>"
    $Report = $Report -Replace "<td>DefaultSharingLinkType:</td><td>AnonymousAccess</td>", "<td>DefaultSharingLinkType:</td><td class='red'>AnonymousAccess</td>"
    return $Report
}

<# Mail Domain section #>
function checkMailDomainReport {
    Write-Host "Checking domains"
    $Domains = Get-DkimSigningConfig | Select-Object -Property Id, @{Name = "Default"; Expression = { $_.IsDefault } }, @{Name = "DKIM"; Expression = { $_.Enabled } }
    if (-not ($Domains)) { $Domains = Get-AcceptedDomain | Select-Object -Property Id, "Default", @{Name = "DKIM"; Expression = { $false } } }
    $DomainsReport = @()
    foreach ($Domain in $Domains) {
        $ProcessedCount++
        Write-Progress -Activity "Processed count: $ProcessedCount; Currently processing: $($Domain.Id)"
        $Domain = checkDMARC -Domain $Domain
        $Domain = checkSPF -Domain $Domain
        $DomainsReport += $Domain
    }
    Write-Progress -Activity "Processed count: $ProcessedCount; Currently processing: $($Domain.Id)" -Status "Ready" -Completed
    $Report = $DomainsReport | ConvertTo-Html -As Table -Property Id, DKIM, DMARC, SPF, "DMARC record", "SPF record", "DMARC hint", "SPF hint", "Default" -Fragment -PreContent "<h3 id='EXO_DOMAIN'>Domains</h3>"
    $Report = $Report -Replace "<td>False</td><td>False</td><td>False</td>", "<td class='red'>False</td><td class='red'>False</td><td class='red'>False</td>"
    $Report = $Report -Replace "<td>False</td><td>False</td><td>True</td>", "<td class='red'>False</td><td class='red'>False</td><td>True</td>"
    $Report = $Report -Replace "<td>True</td><td>False</td><td>False</td>", "<td>True</td><td class='red'>False</td><td class='red'>False</td>"
    $Report = $Report -Replace "<td>True</td><td>False</td><td>True</td>", "<td>True</td><td class='red'>False</td><td>True</td>"
    $Report = $Report -Replace "<td>False</td><td>True</td><td>False</td>", "<td class='red'>False</td><td>True</td><td class='red'>False</td>"
    $Report = $Report -Replace "<td>False</td><td>True</td><td>True</td>", "<td class='red'>False</td><td>True</td><td>True</td>"
    $Report = $Report -Replace "<td>Should be p=reject</td>", "<td class='orange'>Should be p=reject</td>"
    $Report = $Report -Replace "<td>Not sufficiently stricth</td>", "<td class='orange'>Not sufficiently strict</td>"
    $Report = $Report -Replace "<td>Not effective enough</td>", "<td class='red'>Not effective enough</td>"
    $Report = $Report -Replace "<td>Does not protect</td>", "<td class='red'>Does not protect</td>"
    $Report = $Report -Replace "<td>No qualifier found</td>", "<td class='red'>No qualifier found</td>"
    return $Report
}
function checkDMARC {
    param($Domain)
    if ($PSVersionTable.Platform -eq "Unix") { $DMARCRecord = (Resolve-Dns -Query "_dmarc.$($Domain.Id)" -QueryType TXT | Select-Object -Expand Answers).Text }
    else { $DMARCRecord = Resolve-DnsName -Name "_dmarc.$($Domain.Id)" -Type TXT -ErrorAction SilentlyContinue | Select-Object -ExpandProperty strings }
    if ($null -eq $DMARCRecord ) {
        $DMARC = $false
    }
    else {
        switch -Regex ($DMARCRecord ) {
                ('p=none') {
                $DmarcHint = "Does not protect"
                $DMARC = $true
            }
                ('p=quarantine') {
                $DmarcHint = "Should be p=reject"
                $DMARC = $true
            }
                ('p=reject') {
                $DmarcHint = "Will protect"
                $DMARC = $true
            }
                ('sp=none') {
                $DmarcHint += "Does not protect"
                $DMARC = $true
            }
                ('sp=quarantine') {
                $DmarcHint += "Should be p=reject"
                $DMARC = $true
            }
                ('sp=reject') {
                $DmarcHint += "Will protect"
                $DMARC = $true
            }
        }
    }
    $Domain | Add-Member NoteProperty "DMARC" $DMARC
    $Domain | Add-Member NoteProperty "DMARC record" "$($DMARCRecord )"
    $Domain | Add-Member NoteProperty "DMARC hint" $DmarcHint
    return $Domain
}
function checkSPF {
    param($Domain)
    if ($PSVersionTable.Platform -eq "Unix") { $SPFRecord = (Resolve-Dns -Query $Domain.Id -QueryType TXT | Select-Object -Expand Answers).Text | where-object { $_ -match "v=spf1" } }
    else { $SPFRecord = Resolve-DnsName -Name $Domain.Id -Type TXT -ErrorAction SilentlyContinue | where-object { $_.strings -match "v=spf1" } | Select-Object -ExpandProperty strings }
    if ($SPFRecord -match "redirect") {
        $redirect = $SPFRecord.Split(" ")
        $RedirectName = $redirect -match "redirect" -replace "redirect="
        if ($PSVersionTable.Platform -eq "Unix") { $SPFRecord = (Resolve-Dns -Query $RedirectName -QueryType TXT | Select-Object -Expand Answers).Text | where-object { $_ -match "v=spf1" } }
        else { $SPFRecord = Resolve-DnsName -Name $RedirectName -Type TXT -ErrorAction SilentlyContinue | where-object { $_.strings -match "v=spf1" } | Select-Object -ExpandProperty strings }
    }
    if ($null -eq $SPFRecord) {
        $SPF = $false
    }
    if ($SPFRecord -is [array]) {
        $SPFHint = "More than one SPF-record"
        $SPF = $true
    }
    Else {
        switch -Regex ($SPFRecord) {
            '~all' {
                $SPFHint = "Not sufficiently strict"
                $SPF = $true
            }
            '-all' {
                $SPFHint = "Sufficiently strict"
                $SPF = $true
            }
            "\?all" {
                $SPFHint = "Not effective enough"
                $SPF = $true
            }
            '\+all' {
                $SPFHint = "Not effective enough"
                $SPF = $true
            }
            Default {
                $SPFHint = "No qualifier found"
                $SPF = $true
            }
        }
    }
    $Domain | Add-Member NoteProperty "SPF" "$($SPF)"
    $Domain | Add-Member NoteProperty "SPF record" "$($SPFRecord)"
    $Domain | Add-Member NoteProperty "SPF hint" $SPFHint
    return $Domain
}

<# Mail connector section#>
function checkMailConnectorReport {
    Write-Host "Checking mail connectors"
    if (-not ($Inbound = Get-InboundConnector)) { $InboundReport = "<br><h3 id='EXO_CONNECTOR_IN'>Inbound mail connector</h3><p>Not found</p>" }
    else { $InboundReport = $Inbound | ConvertTo-Html -As Table -Property Name, SenderDomains, SenderIPAddresses, Enabled -Fragment -PreContent "<br><h3 id='EXO_CONNECTOR_IN'>Inbound mail connector</h3>" }
    if (-not ($Outbound = Get-OutboundConnector -IncludeTestModeConnectors:$true)) { $OutboundReport = "<br><h3 id='EXO_CONNECTOR_OUT'>Outbound mail connector</h3><p>Not found</p>" }
    else { $OutboundReport = $Outbound | ConvertTo-Html -As Table -Property Name, RecipientDomains, SmartHosts, Enabled -Fragment -PreContent "<br><h3 id='EXO_CONNECTOR_OUT'>Outbound mail connector</h3>" }
    $Report = @()
    $Report += $InboundReport
    $Report += $OutboundReport
    return $Report
}

<# User mailbox section #>
function checkMailboxReport {
    param(
        [System.Boolean]$Language
    )
    Write-Host "Checking user mailboxes"
    if ( -not ($Mailboxes = Get-EXOMailbox -RecipientTypeDetails UserMailbox -ResultSize:Unlimited -Properties DisplayName, UserPrincipalName)) {
        return "<br><h3 id='EXO_USER'>User mailbox</h3><p>Not found</p>"
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
        -Fragment -PreContent "<br><h3 id='EXO_USER'>User mailbox</h3>"
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
        return "<br><h3 id='EXO_SHARED'>Shared mailbox</h3><p>Not found</p>"
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
    $Report = $MailboxReport | ConvertTo-HTML -As Table -Property UserPrincipalName, DisplayName, Language, TimeZone, MessageCopyForSentAsEnabled,
    MessageCopyForSendOnBehalfEnabled, LoginAllowed -Fragment -PreContent "<br><h3 id='EXO_SHARED'>Shared mailbox</h3>"
    $Report = $Report -Replace "<td>True</td><td>True</td><td>True</td>", "<td>True</td><td>True</td><td class='red'>True</td>"
    $Report = $Report -Replace "<td>False</td><td>False</td><td>True</td>", "<td>False</td><td>False</td><td class='red'>True</td>"
    $Report = $Report -Replace "<td>True</td><td>False</td><td>True</td>", "<td>True</td><td>False</td><td class='red'>True</td>"
    $Report = $Report -Replace "<td>False</td><td>True</td><td>True</td>", "<td>False</td><td>True</td><td class='red'>True</td>"
    return $Report
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
        return "<br><h3 id='EXO_UNIFIED'>Unified mailbox</h3><p>Not found</p>"
    }
    if ($HideFromClient) {
        Write-Host "Hiding unified mailboxes from outlook client"
        $Mailboxes | Set-UnifiedGroup -HiddenFromExchangeClientsEnabled:$true -HiddenFromAddressListsEnabled:$false
        $Mailboxes = Get-UnifiedGroup -ResultSize Unlimited 
    }
    return $Mailboxes | Sort-Object -Property PrimarySmtpAddress | ConvertTo-HTML -As Table -Property DisplayName, PrimarySmtpAddress, HiddenFromAddressListsEnabled, HiddenFromExchangeClientsEnabled -Fragment -PreContent "<br><h3 id='EXO_UNIFIED'>Unified mailbox</h3>"
}

<# HTML table of content section #>
$Toc = @()
$GlobalToc = "<br><hr><h2>Contents</h2>"
$AADToc = @"
<h3 class='TOC'><a href="#AAD">Azure Active Directory</a></h3>
<ul>
    <li><a href="#AAD_USER_SETTINGS">Tenant user settings</a></li>
    <li><a href="#AAD_SKU">Licenses</a></li>
    <li><a href="#AAD_ADMINS">Admin role assignments</a></li>
    <li><a href="#AAD_BG">BreakGlass account</a></li>
    <li><a href="#AAD_MFA">User MFA status</a></li>
    <li><a href="#AAD_GUEST">Guest accounts</a></li>
    <li><a href="#AAD_SEC_DEFAULTS">Security Defaults</a></li>
    <li><a href="#AAD_CA">Conditional Access policies</a></li>
    <li><a href="#AAD_CA_LOCATIONS">Named locations</a></li>
    <li><a href="#AAD_APP_POLICY">App protection policies</a></li>
</ul>
"@
$SPOToc = @"
<h3 class='TOC'><a href="#SPO">SharePoint Online</a></h3>
<ul>
    <li><a href="#SPO_SETTINGS">Tenant settings</a></li>
</ul>
"@
$EXOToc = @"
<h3 class='TOC'><a href="#EXO">Exchange Online</a></h3>
<ul>
    <li><a href="#EXO_DOMAIN">Domains</a></li>
    <li><a href="#EXO_CONNECTOR_IN">Inbound mail connector</a></li>
    <li><a href="#EXO_CONNECTOR_OUT">Outbound mail connector</a></li>
    <li><a href="#EXO_USER">User mailbox</a></li>
    <li><a href="#EXO_SHARED">Shared mailbox</a></li>
    <li><a href="#EXO_UNIFIED">Unified mailbox</a></li>
</ul>
"@
$Toc += $GlobalToc
$Toc += $AADToc

<# Script logic start section #>
CheckInteractiveMode -Parameters $PSBoundParameters
if ($script:InteractiveMode) {
    InteractiveMenu
}

connectGraph
if ($script:AddSharePointOnlineReport -or $script:DisableAddToOneDrive) { 
    connectSpo
    $Toc += $SPOToc
}
if ($script:AddExchangeOnlineReport -or $script:SetMailboxLanguage -or $script:DisableSharedMailboxLogin -or $script:EnableSharedMailboxCopyToSent -or $script:HideUnifiedMailboxFromOutlookClient) {
    connectExo
    $Toc += $EXOToc
}

$Report = @()
$Report += organizationReport
$Report += $Toc
$Report += "<br><hr><h2 id='AAD'>Azure Active Directory</h2>"
$Report += checkTenanUserSettingsReport -DisableUserConsent $script:DisableEnterpiseApplicationUserConsent -DisableUsersToCreateAppRegistrations $script:DisableUsersToCreateAppRegistrations -DisableUsersToReadOtherUsers $script:DisableUsersToReadOtherUsers -DisableUsersToCreateSecurityGroups $script:DisableUsersToCreateSecurityGroups -EnableBlockMsolPowerShell $script:EnableBlockMsolPowerShell
$Report += checkUsedSKUReport
$Report += checkAdminRoleReport
$Report += checkBreakGlassAccountReport -Create $script:CreateBreakGlassAccount
$Report += checkUserMfaStatusReport
$Report += checkGuestUserReport
$Report += checkSecurityDefaultsReport -Enable $script:EnableSecurityDefaults -Disable $script:DisableSecurityDefaults
$Report += checkConditionalAccessPolicyReport
$Report += checkNamedLocationReport
$Report += checkAppProtectionPolicesReport

if ($script:AddSharePointOnlineReport -or $script:DisableAddToOneDrive) {
    $Report += "<br><hr><h2 id='SPO'>SharePoint Online</h2>"
    $Report += checkSpoTenantReport -DisableAddToOneDrive $script:DisableAddToOneDrive
}
if ($script:AddExchangeOnlineReport -or $script:SetMailboxLanguage -or $script:DisableSharedMailboxLogin -or $script:EnableSharedMailboxCopyToSent -or $script:HideUnifiedMailboxFromOutlookClient) {
    $Report += "<br><hr><h2 id='EXO'>Exchange Online</h2>"
    $Report += checkMailDomainReport
    $Report += checkMailConnectorReport
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
a {
    font-family: Arial, Helvetica, sans-serif;
    font-size: 16px;
    text-decoration: none;
    color: #666666;
}
ul {
    list-style-type: none;
    margin-top: 5px;
}
li {
    padding: 5px;
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
.red {
    color: red;
}
.orange {
    color: orange;
}
.TOC {
    margin: 5px;
}
#FootNote {
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
<p id='FootNote'>$($VersionMessage)</p>
<p id='FootNote'>Creation date: $(Get-Date -Format "dd.MM.yyyy HH:mm")</p>
<img src="$($LogoImageUrl)" width='75'>
"@
Write-Host "Generating HTML report:" $ReportName
$Report = ConvertTo-HTML -Body "$ReportTitleHtml $Report" -Title $ReportTitle -Head $Header -PostContent $PostContentHtml
$Report | Out-File $Desktop\$ReportName
Invoke-Item $Desktop\$ReportName
if ($script:InteractiveMode -and $script:CreateBreakGlassAccount) { Read-Host "Click [ENTER] key to exit AzureAdDeployer" }