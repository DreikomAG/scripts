#CSS codes
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false)]
    [switch]$Install,
    [Parameter(Mandatory = $false)]
    [switch]$SetDefault,    
    [Parameter(Mandatory = $false)]
    [switch]$UseExistingExoSession
    # [Parameter(Mandatory = $false)]
    # [string[]]$Paths = $null
)
$Version = "1.0.0"
$script:ExoConnected = $false

Write-Host "AzureAdDeployer Version " $Version

$ReportTitle = "AzureAdDeployer Report"
$ReportTitleHtml = "<h1>" + $ReportTitle + "</h1>"

$PostContentHtml = "<p id='CreationDate'>Creation Date: $(Get-Date)</p>"

function installEXO {
    if (Get-Module -Name ExchangeOnlineManagement -ListAvailable) {
        Write-Host "Updating PowerShell ExchangeOnline Module"
        Update-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
    }

    if (-not (Get-Module -Name ExchangeOnlineManagement -ListAvailable)) {
        Write-Host "Installing PowerShell ExchangeOnline Module"
        Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
    }
}

function installGraph {
    if (Get-Module -Name Microsoft.Graph -ListAvailable) {
        Write-Host "Updating PowerShell Graph SDK Module"
        Update-Module -Name Microsoft.Graph -Scope CurrentUser -Force
    }

    if (-not (Get-Module -Name Microsoft.Graph -ListAvailable)) {
        Write-Host "Installing PowerShell Graph SDK Module"
        Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force
    }
}

# function installAzureAd {
#     if (Get-Module -Name AzureAD -ListAvailable) {
#         Write-Host "Updating PowerShell AzureAD Module"
#         Update-Module -Name AzureAD -Scope CurrentUser -Force
#     }

#     if (-not (Get-Module -Name AzureAD -ListAvailable)) {
#         Write-Host "Installing PowerShell AzureAD Module"
#         Install-Module -Name AzureAD -Scope CurrentUser -Force
#     }
# }

function connectExo {
    if ($UseExistingExoSession) { return }
    if (-not $script:ExoConnected) {
        Write-Host "Connecting to EXO"
        Connect-ExchangeOnline -ShowBanner:$false
    }
    $script:ExoConnected = $true
}

function disconnectExo {
    if ($UseExistingExoSession) { return }
    if ($script:ExoConnected) {
        Write-Host "Disconnecting to EXO"
        Disconnect-ExchangeOnline -Confirm:$false
    }
    $script:ExoConnected = $false
}

function checkMailboxLang {
    connectExo
    Write-Host "Generating User Mailbox Language Report"
    return Get-EXOMailbox -ResultSize:Unlimited | Get-MailboxRegionalConfiguration | ConvertTo-HTML -As Table -Property Identity, Language, TimeZone `
        -Fragment -PreContent "<h2>User Mailbox Language</h2>"
}

function setMailboxLang {
    connectExo
    Write-Host "Set Mailbox Lang CH"
    Get-EXOMailbox | Set-MailboxRegionalConfiguration -LocalizeDefaultFolderName:$true -Language de-CH -TimeZone "W. Europe Standard Time" 
}

function checkSharedMailbox {
    connectExo
    Write-Host "Checking SharedMailboxes"
    return Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize:Unlimited -Properties DisplayName, UserPrincipalName, `
        MessageCopyForSentAsEnabled, MessageCopyForSendOnBehalfEnabled | ConvertTo-HTML -As Table -Property DisplayName, `
        UserPrincipalName, MessageCopyForSentAsEnabled, MessageCopyForSendOnBehalfEnabled -Fragment -PreContent "<h2>Shared Mailbox Overview</h2>"
}

function setSharedMailboxEnableCopyToSent {
    connectExo
    Write-Host "SharedMailbox enable copy to sent folder"
    Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize:Unlimited | Set-Mailbox -MessageCopyForSentAsEnabled $True -MessageCopyForSendOnBehalfEnabled $True
}

if ($Install) {
    Write-Host "Installing prerequisite"
    installEXO
    installGraph
    # installAzureAd
    return
}

if ($SetDefault) {
    Write-Host "Set Default Settings"
    setMailboxLang
    setSharedMailboxEnableCopyToSent
}

$MailboxLang = checkMailboxLang
$SharedMailbox = checkSharedMailbox

disconnectExo


$Header = @"
<style>

h1 {

    font-family: Arial, Helvetica, sans-serif;
    color: #666666;
    font-size: 28px;

}


h2 {

    font-family: Arial, Helvetica, sans-serif;
    color: #666666;
    font-size: 16px;
    
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

$Desktop = [Environment]::GetFolderPath("Desktop")

Write-Host "Generating HTML Report"
$Report = ConvertTo-HTML -Body "$ReportTitleHtml $MailboxLang $SharedMailbox" -Title $ReportTitle -Head $Header -PostContent $PostContentHtml
$Report | Out-File $Desktop\AzureAdDeployer-Report.html
Invoke-Item $Desktop\AzureAdDeployer-Report.html