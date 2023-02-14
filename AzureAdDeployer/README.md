# AzureAdDeployer

## Features

### General

- Generates a HTML report to your Desktop called `AzureAdDeployer-Report.html`

- Interactive console GUI

### Azure Active Directory

- Admin role assignments: show

- BreakGlass account: show, create

- Security Defaults: show, enable, disable

- Conditional Access policies: show

- App protection policies: show

- Enterprise Application user consent: show, disable

### Exchange Online

- User mailbox: show, set language

- Shared mailbox: show, set language, disable login, enable copy to sent

- Unified mailbox: show, hide from client

## Infos

- No local administrator privileges required

- Works on PowerShell 5.1 and PowerShell Core

## Arguments

### General

| Argument | Description |
| --- | --- |
| `-Install` | Install or update required PowerShell modules |

### Azure Active directory

| Argument | Description |
| --- | --- |
| `-CreateBreakGlassAccount` | Create a BreakGlass Account if no one is found |
| `-EnableSecurityDefaults` | Enable Security defaults |
| `-DisableSecurityDefaults` | Disable Security defaults |
| `-DisableEnterpiseApplicationUserConsent` | Disable Enterprise Application user consent |

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
| `-UseExistingExoSession` | Do not create a new Exchange Online PowerShell session |
| `-KeepGraphSessionAlive` | Do not disconnect the Graph SDK PowerShell session after execution |
| `-KeepExoSessionAlive` | Do not disconnect the Exchange Online PowerShell session after execution |

## Usage

Note: none of the commands require local administrator privileges on the computer!

### Install required PowerShell modules

`.\AzureAdDeployer.ps1 -Install`

### Interactive GUI

`.\AzureAdDeployer.ps1`

### Azure Active Directory + Exchange Online HTML report

`.\AzureAdDeployer.ps1 -AddExchangeOnlineReport`

### Create a BreakGlass account

`.\AzureAdDeployer.ps1 -CreateBreakGlassAccount`

### Disable Security Defaults

`.\AzureAdDeployer.ps1 -DisableSecurityDefaults`

## ToDo

- MFA methods show

- Manage Self-service Password Reset

- Create default Conditinal Access polices

- List verified Domains

- Create default application protectin policy for iOS and Android

- List unused licenses

- List all user + licenses

## Credits

### Icons

- <a href="https://www.flaticon.com/free-icons/error" title="error icons">Error icons created by Smashicons - Flaticon</a>