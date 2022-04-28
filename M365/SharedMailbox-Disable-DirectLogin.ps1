
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [switch]$secure ## $true = shared mailbox login will be automatically disabled, $false = report only
    )

$processmessagecolor = "green"
$errormessagecolor = "red"

Connect-ExchangeOnline
Connect-AzureAD

write-host -ForegroundColor $processmessagecolor "Getting shared mailboxes"
$Mailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize:Unlimited
write-host -ForegroundColor $processmessagecolor "Start checking shared mailboxes"
write-host
foreach ($mailbox in $mailboxes) {
    $accountdetails=get-azureaduser -objectid $mailbox.userprincipalname        ## Get the Azure AD account connected to shared mailbox
    If ($accountdetails.accountenabled){                                        ## if that login is enabled
        Write-host -foregroundcolor $errormessagecolor $mailbox.displayname,"["$mailbox.userprincipalname"] - Direct Login ="$accountdetails.accountenabled
        If ($secure) {                                                          ## if the secure variable is true disable login to shared mailbox
            Set-AzureADUser -ObjectID $mailbox.userprincipalname -AccountEnabled $false     ## disable shared mailbox account
            $accountdetails=get-azureaduser -objectid $mailbox.userprincipalname            ## Get the Azure AD account connected to shared mailbox again
            write-host -ForegroundColor $processmessagecolor "*** SECURED"$mailbox.displayname,"["$mailbox.userprincipalname"] - Direct Login ="$accountdetails.accountenabled
        }
    } else {
        Write-host -foregroundcolor $processmessagecolor $mailbox.displayname,"["$mailbox.userprincipalname"] - Direct Login ="$accountdetails.accountenabled
    }
}
write-host -ForegroundColor $processmessagecolor "`nFinish checking mailboxes"