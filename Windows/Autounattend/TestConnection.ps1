[CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Script = $null
    )

while (-not $completed) {
    if (((Test-NetConnection google.com -Port 80 -InformationLevel "Detailed").TcpTestSucceeded) -eq $true) {       
        Powershell.exe -ExecutionPolicy Bypass $Script
        $completed = $true         
    } else {
        Start-Sleep '5'
    }
}