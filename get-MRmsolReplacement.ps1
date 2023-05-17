# get-MRmsolReplacement.ps1
# The idea was to get the exact same result as running Get-MSolAccountSku, let me know what you think.
Connect-Graph "Directory.Read.All","Directory.ReadWrite.All","Organization.Read.All","Organization.ReadWrite.All"
$mgSubscribedSkus=Get-MgSubscribedSku
$mgSubscribedSkus
$LicensesReport = New-Object System.Collections.ArrayList

foreach($mgSubscribedSku in $mgSubscribedSkus){
$sku = New-Object PSObject
$sku | Add-Member -MemberType NoteProperty -Name SkuPartNumber -Value $mgSubscribedSku.SkuPartNumber
$sku | Add-Member -MemberType NoteProperty -Name ActiveUnits -Value $mgSubscribedSku.PrepaidUnits.Enabled
$sku | Add-Member -MemberType NoteProperty -Name WarningUnits -Value $mgSubscribedSku.PrepaidUnits.Warning
$sku | Add-Member -MemberType NoteProperty -Name ConsumedUnits -Value $mgSubscribedSku.ConsumedUnits
$LicensesReport.Add($sku)
}
$LicensesReport