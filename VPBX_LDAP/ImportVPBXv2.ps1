# Ändere in das Verzeichnis des aktuellen Skripts
Set-Location $PSScriptRoot

# Pfad zur Konfigurationsdatei (die sich im selben Ordner wie das Skript befindet)
$ConfigPath = ".\config.txt"

# Konfiguration aus der Datei laden
$Config = Get-Content $ConfigPath | ConvertFrom-StringData
$clientname = $Config.Kundenname

# Protokollierung starten (legt die Datei im Skript-Verzeichnis ab)
Start-Transcript -Path ".\Importlogs.log"

# Pfad zu weiteren Konfigurationsdateien
$ldapConfigPath = ".\ldapconfig.txt"
$vpbxConfigPath = ".\vpbxconfig.txt"
$smtpConfigPath = ".\smtpconfig.txt"

# Pfad zur Ausgabedatei (UTF-8-kodierte CSV-Datei)
$outputFilePath = ".\slapd.csv"

try {
    # Konfigurationsdaten aus den Dateien lesen
    $ldapConfig = Get-Content $ldapConfigPath | ConvertFrom-StringData
    $vpbxConfig = Get-Content $vpbxConfigPath | ConvertFrom-StringData
    $smtpConfig = Get-Content $smtpConfigPath | ConvertFrom-StringData

    # E-Mail Einstellungen
    $smtpServer = $smtpConfig.smtpServer
    $smtpFrom= $smtpConfig.Absender
    $smtpTo = $smtpConfig.Empfänger
    $subject = $smtpConfig.Betreff
    $body = ""  

    # LDAP-Verbindungsinformationen
    $LDAPServer = $ldapConfig.LDAPServer
    $LDAPPort = $ldapConfig.LDAPPort
    $LdapUser = $ldapConfig.LdapUser
    $LdapPassword = $ldapConfig.LdapPassword
    $LDAPBaseDN = $ldapConfig.LDAPBaseDN

    # VPBX-Verbindungsinformationen
    $UrlVPBX = $vpbxConfig.URL
    $ApiUserVPBX = $vpbxConfig.username 
    $ApiPasswordVPBX = $vpbxConfig.password

    # LDAP-Suchparameter
    $searchParameters = "(objectClass=*)"

    # Vorhandene CSV-Datei löschen, falls vorhanden
    if (Test-Path $outputFilePath) {
        Remove-Item $outputFilePath -Force
    }

    # LDAP-Daten abrufen und in CSV-Datei schreiben
    $directorySearcher = New-Object DirectoryServices.DirectorySearcher
    $directorySearcher.SearchRoot = New-Object DirectoryServices.DirectoryEntry("LDAP://${LDAPServer}:${LDAPPort}/$LDAPBaseDN", $LdapUser, $LdapPassword, "None")
    $directorySearcher.Filter = $searchParameters
    $directorySearcher.SearchScope = "Subtree"
    $directorySearcher.PageSize = 1000

    $searchResult = $directorySearcher.FindAll()

    if ($searchResult.Count -gt 0) {
        # LDAP-Daten in CSV-Datei formatieren und schreiben
        $csvContent = foreach ($entry in $searchResult) {
            if ($entry.Properties) {
                $givenName = $entry.Properties["givenName"] -join ";"
                $sn = $entry.Properties["sn"] -join ";"
                $company = $entry.Properties["company"] -join ";"
                $homePhone = $entry.Properties["homePhone"] -join ";"
                $telephoneNumber = $entry.Properties["telephoneNumber"] -join ";"
                $mobile = $entry.Properties["mobile"] -join ";"

                # Objekt für CSV-Ausgabe
                [PSCustomObject]@{
                    GivenName       = $givenName
                    SN              = $sn
                    Company         = $company
                    HomePhone       = $homePhone
                    TelephoneNumber = $telephoneNumber
                    Mobile          = $mobile
                }
            }
        }

        # CSV-Datei erstellen
        $csvContent | Export-Csv -Path $outputFilePath -Encoding UTF8 -NoTypeInformation -Delimiter ";"
        Write-Host "CSV-Datei mit UTF-8 Codierung gespeichert"

        # PHP-Skript ausführen
        Start-Process -FilePath '.\php_script.php' -Wait
        Write-Host "PHP-Skript ausgeführt"

        # Adressbuch importieren
        $ImportPBX = "https://$UrlVPBX/import.php?u=$ApiUserVPBX&p=$ApiPasswordVPBX"
        curl.exe -F "upload_file=@$outputFilePath" $ImportPBX
        Write-Host "Adressbuch erfolgreich importiert"

        # CSV-Datei löschen
        Remove-Item $outputFilePath
        Write-Host "CSV-Datei gelöscht"
    } else {
        Write-Host "Keine Ergebnisse gefunden."
    }
} catch {
    # Fehlerbehandlung und E-Mail senden
    Write-Host "Fehler beim Abrufen der LDAP-Daten: $_"
    if ($_.Exception.InnerException) {
        Write-Host "Inner Exception: $($_.Exception.InnerException.Message)"
    }

    # E-Mail-Körper mit Fehlermeldung
    $body = @"
Es gab einen Fehler beim Skript:
Fehlermeldung: $($_.Exception.Message)

Inner Exception: $($_.Exception.InnerException.Message)

Kunde: $clientname
URL: $UrlVPBX
"@

    # E-Mail senden
    Send-MailMessage -SmtpServer $smtpServer -Port 25 -From $smtpFrom -To $smtpTo -Subject $subject -Body $body
    Write-Host "E-Mail mit Fehlermeldungen gesendet"
}

# Protokollierung stoppen
Stop-Transcript
