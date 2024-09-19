#Pfad zur KonfigurationsOrdner
$ConfigPath = ".\config.txt"
$Config = Get-Content $ConfigPath | ConvertFrom-StringData
$folderPath = ".\"
$clientname = $Config.Kundenname

# Protokollierung starten
Start-Transcript -Path "$folderPath\Importlogs.log"

# Pfad zur Konfigurationsdatei
$ldapConfigPath = "$folderPath\ldapconfig.txt"
$vpbxConfigPath = "$folderPath\vpbxconfig.txt"
$smtpConfigPath = "$folderPath\smtpconfig.txt"

# Pfad zur Ausgabedatei (UTF-8-kodierte CSV-Datei)
$outputFilePath = "$folderPath\slapd.csv"

try {
    # Konfigurationsdaten aus der Datei lesen
    $ldapConfig = Get-Content $ldapConfigPath | ConvertFrom-StringData
    $vpbxConfig = Get-Content $vpbxConfigPath | ConvertFrom-StringData
    $smtpConfig = Get-Content $smtpConfigPath | ConvertFrom-StringData

    # E-Mail Einstellungen
    $smtpServer = $smtpConfig.smtpServer
    $smtpFrom= $smtpConfig.Absender
    $smtpTo = $smtpConfig.Empfänger
    $subject = $smtpConfig.Betreff
    $body = ""  

    # LDAP-Verbindungsinformationen aus der Konfiguration holen
    $LDAPServer = $ldapConfig.LDAPServer
    $LDAPPort = $ldapConfig.LDAPPort
    $LdapUser = $ldapConfig.LdapUser
    $LdapPassword = $ldapConfig.LdapPassword
    $LDAPBaseDN = $ldapConfig.LDAPBaseDN

    # VPBX-Verbindungsinformationen aus der Konfiguration holen
    $UrlVPBX = $vpbxConfig.URL
    $ApiUserVPBX = $vpbxConfig.username 
    $ApiPasswordVPBX = $vpbxConfig.password

    # LDAP-Suchparameter
    $searchParameters = "(objectClass=*)"

    # LDAP-Daten mit ldapsearch abrufen und in CSV-Datei schreiben
    if (Test-Path $outputFilePath) {
        Remove-Item $outputFilePath -Force
    }

    $directorySearcher = New-Object DirectoryServices.DirectorySearcher
    $directorySearcher.SearchRoot = New-Object DirectoryServices.DirectoryEntry("LDAP://${LDAPServer}:${LDAPPort}/$LDAPBaseDN", $LdapUser, $LdapPassword, "None")
    $directorySearcher.Filter = $searchParameters
    $directorySearcher.SearchScope = "Subtree"
    $directorySearcher.PageSize = 1000

    $searchResult = $directorySearcher.FindAll()

    if ($searchResult.Count -gt 0) {
        # LDAP-Daten in CSV-Datei schreiben
        $csvContent = foreach ($entry in $searchResult) {
            if ($entry.Properties) {
                $givenName = $entry.Properties["givenName"] -join ";"
                $sn = $entry.Properties["sn"] -join ";"
                $company = $entry.Properties["company"] -join ";"
                $homePhone = $entry.Properties["homePhone"] -join ";"
                $telephoneNumber = $entry.Properties["telephoneNumber"] -join ";"
                $mobile = $entry.Properties["mobile"] -join ";"

                # Format anpassen
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
        # CSV-Datei schreiben
        $csvContent | Export-Csv -Path $outputFilePath -Encoding UTF8 -NoTypeInformation -Delimiter ";"
        Write-Host "CSV-Datei mit UTF-8 Codierung gespeichert"

        # PHP-Skript mit dem PHP-Interpreter ausführen
        Start-Process -FilePath '$folderPath\php_script.php' -Wait
        Write-Host "PHP-Skript ausgefuehrt"

        # Adressbuch importieren
        $ImportPBX = "https://$UrlVPBX/import.php?u=$ApiUserVPBX&p=$ApiPasswordVPBX"
        curl.exe -F "upload_file=@$outputFilePath" $ImportPBX
        Write-Host "Adressbuch erfolgreich importiert"
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
