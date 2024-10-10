set scriptdir=%~dp0

echo Installcti.ps1 wird ausgeführt...
powershell -ExecutionPolicy Bypass -File "%scriptdir%installcti.ps1" -pbxserver "vpbx.globalcall.ch" -modus "3"

echo Configxpress.ps1 wird ausgeführt...
powershell -ExecutionPolicy Bypass -File "%scriptdir%configxpress.ps1" -packagetoken ""