# "C:\scripts\azure\mcadmin\saplicense\get-BMlicenseInfo.ps1"
# "C:\scripts\azure\mcadmin\saplicense"
Connect-Graph -Scopes Organization.Read.All

$allSKUs = Get-MgSubscribedSku -Property SkuPartNumber, ServicePlans 
$allSKUs | ForEach-Object {
    Write-Host "Service Plan:" $_.SkuPartNumber
    $_.ServicePlans | ForEach-Object {$_}
}