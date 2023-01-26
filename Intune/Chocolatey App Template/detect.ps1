$PackageName = "<package name>"
C:\ProgramData\chocolatey\choco.exe feature enable --name="'useEnhancedExitCodes'" -y
C:\ProgramData\chocolatey\choco.exe list -e $PackageName --local-only
exit $LastExitCode