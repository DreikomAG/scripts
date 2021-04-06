#Deletes and recreates a VM
param (
    [Parameter(Mandatory=$true)]
    [string]$vmOldName,
    [Parameter(Mandatory=$true)]
    [string]$vmNewName,
    [Parameter(Mandatory=$true)]
    [string]$rgName,
    [string]$newLocation #Optional, moves the VM to a new Geographic Location
)

$ErrorActionPreference = "Stop"

Write-Host "Get and shutdown old VM, Create new config"
$SourceVmObject = get-azvm -Name $vmOldName -ResourceGroupName $rgName

if ([string]::IsNullOrEmpty($newLocation)) {    
    $newLocation = $SourceVmObject.Location
    Write-Host "No new location specified, using the current VM's existing location: $newLocation"
}

$SourceVmPowerStatus = (get-azvm -Name $SourceVmObject.Name -ResourceGroupName $SourceVmObject.ResourceGroupName -Status).Statuses | where-object code -like "PowerState*"

if ($SourceVmPowerStatus -ne "VM deallocated") {
    stop-azVm -Name $SourceVmObject.Name -ResourceGroupName $SourceVmObject.ResourceGroupName -Force
    Start-Sleep -Seconds 30 #Wait to ensure VM is shutdown.
}

$NewVmObject = New-AzVMConfig -VMName $vmNewName -VMSize $SourceVmObject.HardwareProfile.VmSize 

Write-Host "Create new Network Objects"
$subnetID = (Get-AzNetworkInterface -ResourceId $SourceVmObject.NetworkProfile.NetworkInterfaces[0].id).IpConfigurations.Subnet.id

$nic = New-AzNetworkInterface -Name "$($vmNewName.ToLower())-0-nic" -ResourceGroupName $SourceVmObject.ResourceGroupName  -Location $SourceVmObject.Location -SubnetId $SubnetId 

Add-AzVMNetworkInterface -VM $NewVmObject -Id $nic.Id

Write-Host "Move OS Disk"
$SourceOsDiskSku = (get-azdisk -ResourceGroupName $SourceVmObject.ResourceGroupName -DiskName $SourceVmObject.StorageProfile.OsDisk.name).Sku.Name

$SourceOsDiskSnapConfig =  New-AzSnapshotConfig  -SourceUri $SourceVmObject.StorageProfile.OsDisk.ManagedDisk.Id -Location $SourceVmObject.Location -CreateOption copy

$SourceOsDiskSnap = New-AzSnapshot -Snapshot $SourceOsDiskSnapConfig  -SnapshotName "$($SourceVmObject.Name)-os-snap"  -ResourceGroupName $SourceVmObject.ResourceGroupName

$TargetOsDiskConfig = New-AzDiskConfig -AccountType $SourceOsDiskSku -Location $SourceVmObject.Location -CreateOption Copy -SourceResourceId $SourceOsDiskSnap.Id

$TargetOsDisk = New-AzDisk -Disk $TargetOsDiskConfig -ResourceGroupName $SourceVmObject.ResourceGroupName -DiskName "$($vmNewName.ToLower())-os-vhd"

Set-AzVMOSDisk -VM $NewVmObject -ManagedDiskId $TargetOsDisk.Id -CreateOption Attach $SourceVmObject.StorageProfile.OSDisk.OsType

$NewVmObject.StorageProfile.OSDisk.OsType = $SourceVmObject.StorageProfile.OSDisk.OsType
$NewVmObject.StorageProfile.OSDisk.Name = "$($vmNewName.ToLower())-os-vhd"

Write-Host "Create new Data Disks"
Foreach ($SourceDataDisk in $SourceVmObject.StorageProfile.DataDisks) { 

    $SourceDataDiskSku = (get-azdisk -ResourceGroupName $SourceVmObject.ResourceGroupName -DiskName $SourceDataDisk.name).Sku.Name

    $SourceDataDiskSnapConfig =  New-AzSnapshotConfig  -SourceUri $SourceDataDisk.ManagedDisk.Id -Location $SourceVmObject.Location -CreateOption copy

    $SourceDataDiskSnap = New-AzSnapshot -Snapshot $SourceDataDiskSnapConfig  -SnapshotName "$($SourceVmObject.Name)-$($SourceDataDisk.name)-snap"  -ResourceGroupName $SourceVmObject.ResourceGroupName

    $TargetDataDiskConfig = New-AzDiskConfig -AccountType $SourceDataDiskSku -Location $SourceVmObject.Location -CreateOption Copy -SourceResourceId $SourceDataDiskSnap.Id

    $TargetDataDisk = New-AzDisk -Disk $TargetDataDiskConfig -ResourceGroupName $SourceVmObject.ResourceGroupName -DiskName "$($vmNewName.ToLower())-$($SourceDataDisk.lun)-vhd"


    Add-AzVMDataDisk -VM $NewVmObject -Name "$($vmNewName.ToLower())-$($SourceDataDisk.lun)-vhd" -ManagedDiskId $TargetDataDisk.Id -Lun $SourceDataDisk.lun -CreateOption "Attach"
}

Write-Host "Creating..."
New-AzVM -VM $NewVmObject -ResourceGroupName $SourceVmObject.ResourceGroupName -Location $SourceVmObject.Location
Write-Host "VM Created..."