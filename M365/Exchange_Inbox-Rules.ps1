$mailboxes = get-mailbox | select -Expand Identity
Foreach ($identity in $mailboxes) {
    Get-InboxRule -Mailbox $identity | Select-Object MailboxOwnerId,Name,Description,MoveToFolder,ForwardTo | export-csv services.csv -Append
    } 