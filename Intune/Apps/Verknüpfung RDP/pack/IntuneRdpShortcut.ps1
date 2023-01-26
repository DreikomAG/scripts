    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String]$RdpTargetServer,

        [Parameter(Mandatory = $true)]
        [String]$ShortcutDisplayName
    )


    function Get-DesktopDir
    {
        [CmdletBinding()]
        param()
        process{
            #if (Test-RunningAsSystem){
            #    $desktopDir = Join-Path -Path $env:PUBLIC -ChildPath "Desktop"
            #}else{
            $desktopDir = $([Environment]::GetFolderPath("Desktop") )
            #}
            return $desktopDir
        }
    }

    $wshshell = New-Object -ComObject WScript.Shell

    $path = Join-Path -Path $( Get-DesktopDir ) -ChildPath "$shortcutDisplayName.lnk"

    $lnk = $wshshell.CreateShortcut($path)

    $lnk.TargetPath = "%windir%\system32\mstsc.exe"

    #$lnk.Arguments = "/v:Test.com "

    #$lnk.Description = "AdminBase"
    $rdpFile = @"
screen mode id:i:1
use multimon:i:1
desktopwidth:i:1920
desktopheight:i:1080
session bpp:i:32
winposstr:s:0,1,732,144,1389,644
compression:i:1
keyboardhook:i:2
audiocapturemode:i:1
videoplaybackmode:i:1
connection type:i:7s
networkautodetect:i:1
bandwidthautodetect:i:1
displayconnectionbar:i:1
enableworkspacereconnect:i:0
disable wallpaper:i:0
allow font smoothing:i:0
allow desktop composition:i:0
disable full window drag:i:1
disable menu anims:i:1
disable themes:i:0
disable cursor setting:i:0
bitmapcachepersistenable:i:1
full address:s:$RdpTargetServer
audiomode:i:0
redirectprinters:i:0
redirectcomports:i:0
redirectsmartcards:i:1
redirectclipboard:i:1
redirectposdevices:i:0
autoreconnection enabled:i:1
authentication level:i:0
prompt for credentials:i:0
negotiate security layer:i:1
remoteapplicationmode:i:0
alternate shell:s:
shell working directory:s:
gatewayhostname:s:
gatewayusagemethod:i:4
gatewaycredentialssource:i:4
gatewayprofileusagemethod:i:0
promptcredentialonce:i:0
gatewaybrokeringtype:i:0
use redirection server name:i:0
rdgiskdcproxy:i:0
kdcproxyname:s:
drivestoredirect:s:


"@

    $rdpFile | Out-File (Join-Path -Path $( Get-DesktopDir ) -ChildPath "$shortcutDisplayName.rdp")