$AppName = "Windows Default Apps Cleanup"
$Log_FileName = "win32-$AppName.log"
$Log_Path = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\"
$TestPath = "$Log_Path\$Log_Filename"
$BreakingLine="- - "*10
$SubBreakingLine=". . "*10
$SectionLine="* * "*10

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Message
    )
$timestamp = Get-Date -Format "dddd MM/dd/yyyy HH:mm:ss"
Add-Content -Path $TestPath -Value "$timestamp : $Message"
}


#Begin of the script:

# Start logging [Same file will be used for IME detection]

Write-Log "Begin processing app removal..."
Write-Log $SectionLine

# STEP: Remove built-in Windows packages

Write-Log "Start - Remove built-in Windows packages"
Write-Log $SubBreakingLine


$builtinappstoremove = @(
"Microsoft.windowscommunicationsapps"
"Microsoft.Windows.Photos"
"Microsoft.SkypeApp"
"Microsoft.XboxApp"
"Microsoft.XboxSpeechToTextOverlay"
"Microsoft.XboxGamingOverlay"
"Microsoft.XboxGameOverlay"
"Microsoft.WindowsFeedbackHub"
"Microsoft.Wallet"
"Microsoft.StorePurchaseApp"
"Microsoft.MicrosoftEdge"
"Microsoft.MicrosoftEdge.Stable"
"Microsoft.People"
"Microsoft.MicrosoftStickyNotes"
"Microsoft.MicrosoftSolitaireCollection"
"Microsoft.MicrosoftOfficeHub"
"Microsoft.Microsoft3DViewer"
"Microsoft.Getstarted"
"Microsoft.GetHelp"
"Microsoft.BingWeather"
"Microsoft.BingNews"
"Microsoft.ZuneVideo"
"Microsoft.XboxApp"
"Microsoft.Office.OneNote"
"Microsoft.WindowsAlarms"
"Microsoft.WindowsSoundRecorder"
"Microsoft.ZuneMusic"
"Microsoft.YourPhone"
"Microsoft.WindowsMaps"
"Microsoft.MicrosoftEdgeDevToolsClient"
"Microsoft.EdgeDevtoolsPlugin"
"Microsoft.Print3D"
"MicrosoftTeams"
"Microsoft.Xbox.TCUI"
"Microsoft.XboxGameOverlay"
"Microsoft.XboxIdentityProvider"
"Microsoft.XboxSpeechToTextOverlay"
)

foreach ($app in $builtinappstoremove) {
    Write-Log "Attempting to remove $app"
    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where {$_.DisplayName -eq "$app"} | Remove-AppxProvisionedPackage -Online
    Write-Log "Removed $app"
    Write-Log $SubBreakingLine
}

Write-Log "END - All specified built-in apps were removed succesfully"
Write-Log $BreakingLine