# AzureAdDeployer

## Features

### Azure Active Directory

- BreakGlass account: create, show

- Security Defaults: enable, disable, show

- Conditional Access policies: show

### Exchange Online

- User mailbox: show

- Shared mailbox: show

## Arguments

### Common

| Argument | Description |
| --- | --- |
| `-Install` | Install or update required PowerShell modules |
| `-AddExchangeOnlineReport` | Add a report section for Exchange Online |
| `-CreateBreakGlassAccount` | Create a BreakGlass Account if no one is found |
| `-EnableSecurityDefaults` | Enable Security defaults |
| `-DisableSecurityDefaults` | Disable Security defaults |

### Advanced

| Argument | Description |
| --- | --- |
| `-UseExistingGraphSession` | Do not create a new Graph SDK PowerShell session |
| `-UseExistingExoSession` | Do not create a new Exchange Online PowerShell session |
| `-KeepGraphSessionAlive` | Do not disconnect the Graph SDK PowerShell session after execution |
| `-KeepExoSessionAlive` | Do not disconnect the Exchange Online PowerShell session after execution |

## Usage

Azure Active Directory HTML report:

`.\AzureAdDeployer.ps1`

Azure Active Directory + Exchange Online HTML report:

`.\AzureAdDeployer.ps1 -AddExchangeOnlineReport`

Create a BreakGlass account:

`.\AzureAdDeployer.ps1 -CreateBreakGlassAccount`

Disable Security Defaults:

`.\AzureAdDeployer.ps1 -DisableSecurityDefaults`