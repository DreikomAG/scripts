param (
    [string]$PackageToken
)

$file = @"
<?xml version="1.0"?>

<root>

   <PackageToken>$PackageToken</PackageToken>

   <XpressUrl>https://backend-xpress.jabra.com</XpressUrl>

</root>
"@

# Pfad zur Jabra Direct Konfiguration
$jdPath = Join-Path $env:Programdata "Jabra Direct"

# Pr�fen, ob der Pfad existiert, und gegebenenfalls erstellen
If (-not (Test-Path $jdPath)) { 
    New-Item -ItemType Directory -Path $jdPath 
}

# Speichern der XML-Datei mit dem eingef�gten PackageToken
Set-Content -Path "$jdPath\jabradirect.xml" -Value $file
