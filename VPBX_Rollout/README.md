# VPBX Rollout

## Usage

- Copy all files from folder to the Desktop

- Edit the [install.cmd](./install.cmd) file and replace -pbxserver `<.vpbx.globalcall.ch>` and -modus `1/2/3/4` with your own values.
# Modus: 1=CTI-Client,2=Flexclient, 3=Softphone, 4=flexcore

- Replace unter "PackageToken" your Token from Jabra XPRESS

- Edit [userliste.csv](./userliste.csv) with the SIP-Credentials

# Modus: 1=CTI-Client,2=Flexclient, 3=Softphone, 4=flexcore

## Tasks

### installcti.ps1

- Install Chocolatey

- Install CTI: `choco install wwphonecti -y`

- Install Jabra-Direct: `choco install Jabra-Direct -y`

- Configure Jabra XPRESS with the Packagetoken

- Create a Scheduled Task for Chocolatey Upgrade at Startup `upgrade jabra-direct -y` & `upgrade wwphone-cti -y`

- Interactive User choice xy

- Create CTI.cfg with the SIP-Credentials from the selected User at %localappdata%