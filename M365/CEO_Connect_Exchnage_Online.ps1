$MFAExchangeModule = ((Get-ChildItem -Path $($env:LOCALAPPDATA + "\Apps\2.0\") -Filter CreateExoPSSession.ps1 -Recurse ).FullName | Select-Object -Last 1)
If ($MFAExchangeModule -eq $null) {
  Write-Host  `nPlease install Exchange Online MFA Module.  -ForegroundColor yellow
  Write-Host You can install module using below blog : `nLink `nOR you can install module directly by entering "Y"`n
  $Confirm = Read-Host Are you sure you want to install module directly? [Y] Yes [N] No
  if ($Confirm -match "[yY]") {
    Write-Host Yes
    Start-Process "iexplore.exe" "https://cmdletpswmodule.blob.core.windows.net/exopsmodule/Microsoft.Online.CSE.PSModule.Client.application"
  }
  else {
    Start-Process 'https://o365reports.com/2019/04/17/connect-exchange-online-using-mfa/'
    Exit
  }
  $Confirmation = Read-Host Have you installed Exchange Online MFA Module? [Y] Yes [N] No
  if ($Confirmation -match "[yY]") {
    $MFAExchangeModule = ((Get-ChildItem -Path $($env:LOCALAPPDATA + "\Apps\2.0\") -Filter CreateExoPSSession.ps1 -Recurse ).FullName | Select-Object -Last 1)
    If ($MFAExchangeModule -eq $null) {
      Write-Host Exchange Online MFA module is not available -ForegroundColor red
      Exit
    }
  }
  else { 
    Write-Host Exchange Online PowerShell Module is required
    Start-Process 'https://o365reports.com/2019/04/17/connect-exchange-online-using-mfa/'
    Exit
  }   
}
  
#Importing Exchange MFA Module
write-host aaaa
. "$MFAExchangeModule"
Connect-EXOPSSession -WarningAction SilentlyContinue | Out-Null