param (
    [string]$pbxserver,
    [string]$modus
)

# Prüfen, ob Chocolatey installiert ist
if (!(Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey ist nicht installiert. Installiere Chocolatey..."

    # Setze die Execution Policy und führe die Installation aus
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-Host "Chocolatey ist bereits installiert."
}

# CTI installieren
C:\ProgramData\chocolatey\choco.exe install wwphone-cti -y

# Jabra Direct installieren
C:\ProgramData\chocolatey\choco.exe install jabra-direct -y

# Auto-Updates CTI
$ActionCTI = New-ScheduledTaskAction -Execute "choco.exe" -Argument "upgrade wwphone-cti -y"
$TriggerCTI = New-ScheduledTaskTrigger -AtStartup
$PrincipalCTI = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -Action $ActionCTI -Trigger $TriggerCTI -Principal $PrincipalCTI -TaskName "ChocolateyUpgradeWWPhoneCTI" -Description "Auto upgrade wwphone-cti package at system startup via Chocolatey"

# Auto-Updates Jabradirect
$ActionJabra = New-ScheduledTaskAction -Execute "choco.exe" -Argument "upgrade jabra-direct -y"
$TriggerJabra = New-ScheduledTaskTrigger -AtStartup
$PrincipalJabra = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -Action $ActionJabra -Trigger $TriggerJabra -Principal $PrincipalJabra -TaskName "ChocolateyUpgradeJabraDirect" -Description "Auto upgrade jabra-direct package at system startup via Chocolatey"

# Config Pfad
$LocalAppData = [System.Environment]::GetFolderPath('LocalApplicationData')
$pfad = Join-Path $LocalAppData "CTI"

cd $PSScriptRoot
# CSV-Datei mit Benutzerinformationen laden
$userliste = Import-Csv -Path ".\userliste.csv" -Delimiter ";"

# Benutzer zur Auswahl anzeigen
Write-Host "Wähle einen Benutzer aus:"
for ($i = 0; $i -lt $userliste.Count; $i++) {
    Write-Host "$($i + 1). $($userliste[$i].User)"
}

# Auswahl des Benutzers durch den Nutzer
$selection = Read-Host "Gib die Nummer des Benutzers ein (1, 2, 3, etc.)"
$index = [int]$selection - 1

if ($index -ge 0 -and $index -lt $userliste.Count) {
    $benutzer = $userliste[$index]

    # XML-Datei laden und konfigurieren
    $xmldata =[XML](Get-Content ".\template.cfg")
    $xmldata.CONFIG.Server = $pbxserver
    $xmldata.CONFIG.User = $benutzer.User
    $xmldata.CONFIG.Password = $benutzer.Password
    $xmldata.CONFIG.mode = $modus
    
    # Konfigurationsdatei speichern
    $xmldata.Save((Resolve-Path ".\template.cfg").Path)

    # Zielverzeichnis prüfen und erstellen, falls nicht vorhanden
    if (!(Test-Path $pfad)) {New-Item -Path $pfad -ItemType Directory}

    # Zieldatei kopieren
    Copy-Item ".\template.cfg" -Destination "$pfad\CTI.cfg"

    Write-Host "Konfiguration für $($benutzer.User) erfolgreich erstellt."

    # Reset der Konfigurationsdatei
    $xmldata =[XML](Get-Content '.\template.cfg')
    $xmldata.CONFIG.Server = ''
    $xmldata.CONFIG.User = ''
    $xmldata.CONFIG.Password = ''
    $xmldata.CONFIG.mode = ''
    $xmldata.Save((Resolve-Path ".\template.cfg").Path)

} else {
    Write-Host "Ungültige Auswahl."
}
