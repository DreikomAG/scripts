Start-Transcript -Path ".\Importlogs.log"

# Pfad zur Konfigurationsdatei
$ldapConfigPath = ".\ldapconfig.txt"
$vpbxConfigPath = ".\vpbxconfig.txt"

# Pfad zur Ausgabedatei (UTF-8-kodierte CSV-Datei)
$outputFilePath = ".\slapd.csv"

    # Konfigurationsdaten aus der Datei lesen
    $ldapConfig = Get-Content $ldapConfigPath | ConvertFrom-StringData
    $vpbxConfig = Get-Content $vpbxConfigPath | ConvertFrom-StringData

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
    try {
        # Überprüfen, ob die Ausgabedatei bereits vorhanden ist, und falls ja, löschen
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
        Start-Process -FilePath '.\php_script.php' -Wait
        Write-Host "PHP-Skript ausgefuehrt"

        # Adressbuch importieren
        $ImportPBX = "https://$UrlVPBX/import.php?u=$ApiUserVPBX&p=$ApiPasswordVPBX"
        curl.exe -F "upload_file=@.\slapd.csv" $ImportPBX
        Write-Host "Adressbuch erfolgreich importiert"
        Remove-Item .\slapd.csv
        Write-Host "CSV-Datei gelöscht"

    } else {
        Write-Host "Keine Ergebnisse gefunden."
    }
} catch {
    Write-Host "Fehler beim Abrufen der LDAP-Daten: $_"
    if($_.Exception.InnerException) {
        Write-Host "Inner Exception: $($_.Exception.InnerException.Message)"
    }
}
Stop-Transcript