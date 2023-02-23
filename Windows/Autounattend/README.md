# Autounattend

## Usage

- Copy all files from [Autounattend](./) folder to the Windows installation USB stick root folder

- Edit the [wifi.txt](./wifi.txt) file and replace `<ssid>` and `<psk>` with your own values

    Example `wifi.txt`

    ```raw
    mywlanname
    my$secretpw!
    ```

## Logs

Setup.ps1: `C:\Temp\Autounattend.log`

Chocolatey: `C:\ProgramData\chocolatey\logs\chocolatey.log`

HPIA: `C:\Hpia\HPIAReport`

## Tasks

### Autounattend.xml

- Set Language de-CH

- UEFI Partition 600MB

### Setup.ps1

- Set Registry key for de-CH Language Pack

- Import WLAN profile from wifi.txt

- Install Chocolatey

- Install Adobe Reader: `choco install adobereader -y`

- Install Chocolatey auto upgrades at startup: `choco install choco-upgrade-all-at-startup -y`

- Install and run HP Image Assistant Driver updates

- Install Windows Updates and reboot
