# "get-MGDailyLicensingFigures_MSFT.ps1"
<#
Good
An updated version of the script that utilizes commands from the Microsoft Graph module
instead of the Azure AD and Azure AD Group module:
Please note that you'll need to have the Microsoft Graph module installed
(`Install-Module -Name Microsoft.Graph`) and ensure that you have the 
required permissions to access the Microsoft Graph API for retrieving license information.
Those permissions needed for the script are:
"User.Read", "Group.Read.All"
#>

# A script that will run daily to check license figures from an Azure tenant
# and send an email to the O365 Admin team

# Install the required module if not already installed
if (-not (Get-Module -Name Microsoft.Graph)) {
    Install-Module -Name Microsoft.Graph
}

<#
# Import the Microsoft Graph module # decide if needed
Import-Module -Name Microsoft.Graph
#>
# Connect to Microsoft Graph using a delegated user login
$tenantID = "2phn2l.onmicrosoft.com"
Connect-MgGraph -Scopes "User.Read", "Group.Read.All" -TenantId $tenantID

# Retrieve license figures from Microsoft Graph

# Total E3 licenses
$TotalE3 = (Get-MgAccountSku | Where-Object { $_.AccountSkuId -eq "2phn2l:ENTERPRISEPACK" }).ActiveUnits

# Assigned E3 licenses
$AssignedE3 = (Get-MgAccountSku | Where-Object { $_.AccountSkuId -eq "2phn2l:ENTERPRISEPACK" }).ConsumedUnits

# Available E3 licenses
$AvailableE3 = $TotalE3 - $AssignedE3

# Additional license figures from Microsoft Graph
$AgencyCount = (Get-MgGroup -Filter "displayName eq 'o365_dynamic_office2016_agents_only'" -ExpandMembers).Count
$CAT = (Get-MgGroup -Filter "displayName eq 'o365_dynamic_office2016_c1_only'" -ExpandMembers).Count
$MSA = (Get-MgGroup -Filter "displayName eq 'o365_dynamic_agent_msa'" -ExpandMembers).Count

# Calculate other licensing values based on retrieved figures

# Free licenses (Agency)
$TotalAgencyLimit = 40000
$MSALimit = 1000

$AvailableAgencyLicenses = $TotalAgencyLimit - $AgencyCount
$AgencyLimitLessMSA = $TotalAgencyLimit - $MSALimit
$OnlyAgencyTotal = $AgencyCount - $MSA
$OnlyEntCount = $AssignedE3 - $OnlyAgencyTotal - $CAT
$EntCountWithCAT = $AssignedE3 - $OnlyAgencyTotal
$AvailableAgencyOnly = $TotalAgencyLimit - $OnlyAgencyTotal

# Free licenses (Enterprise)
$TotalEntPurchased = $TotalE3 - $TotalAgencyLimit
$TotalEntLessCAT = $TotalEntPurchased - $CATLimit
$TotalEntLessCATLessMSA = $TotalEntLessCAT - $MSALimit
$AvailableEnt = $TotalEntPurchased - $EntCountWithCAT
$AvailableCAT = $CATLimit - $CAT
$AvailableMSA = $MSALimit - $MSA
$AssignedENTTotal = $AssignedE3 - $OnlyAgencyTotal
$AssignedENTLessCAT = $AssignedENTTotal - $CAT
$AssignedCATPlusMSA = $CAT + $MSA
$AssignedENTLessCATLessMSA = $AssignedENTTotal - $CAT - $MSA
$AvailableEntLessCAT = $TotalEntLessCAT - $AssignedENTLessCAT
$AvailableENTLessCATLessMSA = $TotalEntLessCATLessMSA - $AssignedENTLessCATLessMSA

# Email Configuration
$MyEmail = "LicenseFigures@2phn2l.onmicrosoft.com"
$SMTP = "mail.2phn2l.onmicrosoft.com"
$To = "mcadmin@2phn2l.onmicrosoft.com", "mcadmin@2phn

2l.onmicrosoft.com"
$Subject = "Daily Licensing Summary"

# Construct the email body
$Body = @"
Daily summary of O365 E3 licenses assigned - Breakdown between Enterprise, CAT, MSA, and Agency.

Total Licensing purchased                                      $TotalE3

Total Enterprise Purchased                                    $TotalEntPurchased

Total Agency Purchased (incl MSA)                      $TotalAgencyLimit

Total Assigned                                                          $AssignedE3

Agency & Enterprise Not Assigned                $AvailableE3

*****************************************************************

Enterprise

Enterprise Purchased                                             $TotalEntPurchased

Enterprise Assigned                                               $EntCountWithCAT

Enterprise Available                                               $AvailableEnt


Total CAT Assigned                                                  $CAT

Total MSA Assigned                                                 $MSA


Enterprise Purchased (excl CAT)                           $TotalEntLessCAT

Total CAT Assigned                                                  $CAT

Enterprise Assigned (excl CAT Assigned)             $AssignedENTLessCAT

Enterprise Available (excl CAT)                              $AvailableEntLessCAT


Enterprise Purchased (excl CAT & MSA)             $TotalEntLessCATLessMSA

Total CAT + MSA Assigned                                       $AssignedCATPlusMSA

Enterprise Assigned (excl CAT & MSA Assigned)    $AssignedENTLessCATLessMSA

Enterprise Available (excl CAT & MSA)                 $AvailableENTLessCATLessMSA

***************************************************************

Agency

Agency Assigned (incl MSA)                                      $AgencyCount

Agency Available (incl MSA)                                     $AvailableAgencyLicenses

Agency Assigned (excl MSA)                                      $OnlyAgencyTotal

Agency Available (excl MSA)                                     $AvailableAgencyOnly

****************************************************************

Total CAT Purchased                                                $CATLimit

Total CAT Assigned                                                   $CAT

Total CAT Available                                                  $AvailableCAT

*****************************************************************

Total MSA purchased                                              $MSALimit

Total MSA Assigned                                                 $MSA

Total MSA Available                                                $AvailableMSA

Kind regards,

Jenkins
"@

# Check if the available agency or enterprise licenses fall below the thresholds
if ($AvailableAgencyLicenses -le $AgencyThreshold -or $AvailableEnt -le $EnterpriseThreshold -or $AvailableEntLessCAT -le $EnterpriseThreshold -or $AvailableENTLessCATLessMSA -le $EnterpriseThreshold) {
    # Send an email to the designated recipients
    Send-MailMessage -To $To -From $MyEmail -Subject $Subject -Body $Body -SmtpServer $SMTP -DeliveryNotificationOption Never
}
else {
    # Display the current license figures on the console
    $line = "====================================="
    Write-Host "`n$line"
    Write-Host "Current License Figures `n$line"
    Write-Host "Agency: $AvailableAgencyLicenses"
    Write-Host "Enterprise: $AvailableEnt"
    Write-Host "`n$line"
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
