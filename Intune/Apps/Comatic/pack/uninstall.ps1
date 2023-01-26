$id = Get-WmiObject -Class Win32_Product | where {($_.Name -eq "Comatic Remote Desktop") -and ($_.Vendor -eq "Comatic")}
if ($id.IdentifyingNumber) {
    MsiExec.exe /qn /X $id.IdentifyingNumber 
}