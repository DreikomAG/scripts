# AzureAdDeployer

## Features

### General

- Generates a HTML report to your Desktop called `Microsoft365-Report-<customer_name>.html`

- Interactive console GUI

### Azure Active Directory

- Admin role assignments: show

- User mfa status: show

- BreakGlass account: show, create

- Security Defaults: show, enable, disable

- Conditional Access policies: show

- App protection policies: show

- Enterprise Application user consent: show, disable

### SharePoint Online

- Add to OneDrive: show, disable

- ConditionalAccessPolicy: show

### Exchange Online

- Domains: show

- Mail connector: show

- User mailbox: show, set language

- Shared mailbox: show, set language, disable login, enable copy to sent

- Unified mailbox: show, hide from client

## Infos

- Works on PowerShell Windows and PowerShell Core

## Installation

### Uninstall previously installed modules

PowerShell as user:

```PowerShell
$Documents = [Environment]::GetFolderPath("MyDocuments") 
Remove-Item $Documents\PowerShell\Modules\ -Recurse -Force
Remove-Item $Documents\WindowsPowerShell\Modules\ -Recurse -Force
```

Windows PowerShell 5.1 (not Core!) as Administrator:

```PowerShell
Uninstall-Module -Name Microsoft365DSC

Uninstall-Module Microsoft.Graph
Get-InstalledModule Microsoft.Graph.* | %{ if($_.Name -ne "Microsoft.Graph.Authentication"){ Uninstall-Module $_.Name } }
Uninstall-Module Microsoft.Graph.Authentication

Uninstall-Module -Name PnP.PowerShell

Uninstall-Module -Name ExchangeOnlineManagement
```

### Installation

Windows PowerShell 5.1 (not Core!) as Administrator:

```PowerShell
Install-Module -Name Microsoft.Graph -Scope AllUsers -Force
Install-Module -Name PnP.PowerShell -Scope AllUsers -Force
Install-Module -Name ExchangeOnlineManagement -Scope AllUsers -Force
```

### Updating

Windows PowerShell 5.1 (not Core!) as Administrator:

```PowerShell
Update-Module -Name Microsoft.Graph -Scope AllUsers -Force
Update-Module -Name PnP.PowerShell -Scope AllUsers -Force
Update-Module -Name ExchangeOnlineManagement -Scope AllUsers -Force
```

## Arguments

### Azure Active directory

| Argument | Description |
| --- | --- |
| `-CreateBreakGlassAccount` | Create a BreakGlass Account if no one is found |
| `-EnableSecurityDefaults` | Enable Security defaults |
| `-DisableSecurityDefaults` | Disable Security defaults |
| `-DisableEnterpiseApplicationUserConsent` | Disable Enterprise Application user consent |

### SharePoint Online

| Argument | Description |
| --- | --- |
| `-DisableAddToOneDrive` | Disable add to OneDrive |

### Exchange Online

| Argument | Description |
| --- | --- |
| `-AddExchangeOnlineReport` | Add a report section for Exchange Online |
| `-SetMailboxLanguage` | Set mailbox language and location |
| `-DisableSharedMailboxLogin` | Disable direct login to shared mailbox |
| `-EnableSharedMailboxCopyToSent` | Enable shared mailbox copy to sent e-mails |
| `-HideUnifiedMailboxFromOutlookClient` | Hide unified mailbox from outlook client |

### Advanced

| Argument | Description |
| --- | --- |
| `-UseExistingGraphSession` | Do not create a new Graph SDK PowerShell session |
| `-UseExistingSpoSession` | Do not create a new SharePoint Online PowerShell session |
| `-UseExistingExoSession` | Do not create a new Exchange Online PowerShell session |
| `-KeepGraphSessionAlive` | Do not disconnect the Graph SDK PowerShell session after execution |
| `-KeepSpoSessionAlive` | Do not disconnect the SharePoint Online session after execution |
| `-KeepExoSessionAlive` | Do not disconnect the Exchange Online PowerShell session after execution |

## Usage

### Interactive GUI

`.\AzureAdDeployer.ps1`

### Azure Active Directory + Exchange Online HTML report

`.\AzureAdDeployer.ps1 -AddExchangeOnlineReport`

### Create a BreakGlass account

`.\AzureAdDeployer.ps1 -CreateBreakGlassAccount`

### Disable Security Defaults

`.\AzureAdDeployer.ps1 -DisableSecurityDefaults`

## ToDo

- Manage Self-service password reset (no API available)

- Enable enterpise state roaming (no API available)

- Manage users allowed to join devices to aad (no API available)

- Create default Conditinal Access polices

- List trusted locations

- Check DMARC

- Find external e-mail forwardings

- Create default application protectin policy for iOS and Android

- Manage Enterprise application admin consent request policy <https://learn.microsoft.com/en-us/graph/api/adminconsentrequestpolicy-get?view=graph-rest-1.0&tabs=powershell>

- Check if required Modules are installed and imported -> `#require` is causing performance issues, long script startup times

- List unused licenses

- List Guest accounts

- List externally shared files

- Inegrate Azure PowerShell module <https://learn.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-9.4.0>

  - Check if budget is set

- Set language of admin account to en-US

## Credits

### Icons

- <a href="https://www.flaticon.com/free-icons/error" title="error icons">Error icons created by Smashicons - Flaticon</a>


## Template code for later functions

### Conditional Access policies

```PowerShell
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
```

### Application protection policies

```PowerShell
function createAndroidAppProtectionPolicy {
    $Body = @{
        "@odata.type" = "#microsoft.graph.androidManagedAppProtection"
        displayName = "Test"
    }
    New-MgDeviceAppManagementAndroidManagedAppProtection -BodyParameter $Body
}
```

### List DMARC

```PowerShell
function Get-DMARCRecord {
    [CmdletBinding()]
    param(
        [Parameter(
        )][string]$Name
    )
    begin {
        $SplatParameters = @{
            'Type'        = 'TXT'
            'Name'        = "_dmarc.$($Name)"
            'ErrorAction' = 'SilentlyContinue'
        }
        $DMARCObject = New-Object System.Collections.Generic.List[System.Object]
    }
    Process {
        $DMARC = Resolve-DnsName @SplatParameters | Select-Object -ExpandProperty strings -ErrorAction SilentlyContinue
        if ($null -eq $DMARC) {
            $DmarcAdvisory = "Does not have a DMARC record. This domain is at risk to being abused by phishers and spammers."
        }
        Else {
            $Policy = ""
            switch -Regex ($DMARC) {
                ('p=none') {
                    $DmarcAdvisory = "Domain has a valid DMARC record but the DMARC (subdomain) policy does not prevent abuse of your domain by phishers and spammers."
                    $Policy = "none"
                }
                ('p=quarantine') {
                    $DmarcAdvisory = "Domain has a DMARC record and it is set to p=quarantine. To fully take advantage of DMARC, the policy should be set to p=reject."
                    $Policy = "quarantine"
                }
                ('p=reject') {
                    $DmarcAdvisory = "Domain has a DMARC record and your DMARC policy will prevent abuse of your domain by phishers and spammers. "
                    $Policy = "reject"
                }
                ('sp=none') {
                    $DmarcAdvisory += "The subdomain policy does not prevent abuse of your domain by phishers and spammers."
                    $Policy = "none"
                }
                ('sp=quarantine') {
                    $DmarcAdvisory += "The subdomain has a DMARC record and it is set to sp=quarantine. To prevent you subdomains configure the policy to sp=reject."
                    $Policy = "quarantine"
                }
                ('sp=reject') {
                    $DmarcAdvisory += "The subdomain policy prevent abuse of your domain by phishers and spammers."
                    $Policy = "reject"
                }
            }
        }
    } 
    end {
        $DMARCReturnValues = New-Object psobject
        $DMARCReturnValues | Add-Member NoteProperty "Name" $Name
        $DMARCReturnValues | Add-Member NoteProperty "DmarcRecord" "$($DMARC)"
        $DMARCReturnValues | Add-Member NoteProperty "DmarcAdvisory" $DmarcAdvisory
        $DMARCReturnValues | Add-Member NoteProperty "Policy" $Policy
        $DMARCObject.Add($DMARCReturnValues)
        $DMARCReturnValues
    }
}
```
