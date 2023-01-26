$id = Get-WmiObject -Class Win32_Product | where {($_.Name -eq "Windows Agent") -and ($_.Vendor -eq "N-able Technologies")}
if ($id.IdentifyingNumber) {
    MsiExec.exe /qn /X $id.IdentifyingNumber 
}