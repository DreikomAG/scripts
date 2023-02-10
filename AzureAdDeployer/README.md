# AzureAdDeployer

## Features

### General

- Generates a HTML report to your Desktop called `AzureAdDeployer-Report.html`

### Azure Active Directory

- BreakGlass account: show, create

- Security Defaults: show, enable, disable

- Conditional Access policies: show

### Exchange Online

- User mailbox: show, set language

- Shared mailbox: show, set language

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

### Exchange Online

| Argument | Description |
| --- | --- |
| `-AddExchangeOnlineReport` | Add a report section for Exchange Online |
| `-SetMailboxLanguage` | Set Mailbox language and location |

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

### Azure Active Directory HTML report

`.\AzureAdDeployer.ps1`

### Azure Active Directory + Exchange Online HTML report

`.\AzureAdDeployer.ps1 -AddExchangeOnlineReport`

### Create a BreakGlass account

`.\AzureAdDeployer.ps1 -CreateBreakGlassAccount`

### Disable Security Defaults

`.\AzureAdDeployer.ps1 -DisableSecurityDefaults`
