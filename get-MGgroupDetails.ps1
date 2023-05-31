# "get-MGgroupDetails.ps1"
# replace tenantID with your tenant ID
<#
$tenantID = "2phn2l.onmicrosoft.com"
Connect-MgGraph -Scopes "User.Read", "Group.Read.All" -TenantId $tenantID

# Connect to Microsoft Graph using a delegated user login
Connect-MgGraph -Scopes "Group.Read.All", "User.Read.All" -TenantId $tenantID
#>

# Retrieve all groups in the Azure tenant
$groups = Get-MgGroup -All $true

# Iterate through each group and retrieve membership count and assigned license count
$groupReports = foreach ($group in $groups) {
    $groupId = $group.Id
    $groupDisplayName = $group.DisplayName

    # Get group membership count
    $members = Get-MgGroupMember -GroupId $groupId -All $true
    $membershipCount = $members.Count

    # Get assigned license count for the group
    $assignedLicenses = Get-MgGroup -GroupId $groupId -ExpandLicenseDetails
    $assignedLicenseCount = $assignedLicenses.AssignedLicenseDetails.Count

    # Create a custom object with the group details
    [PSCustomObject]@{
        GroupDisplayName = $groupDisplayName
        MembershipCount = $membershipCount
        AssignedLicenseCount = $assignedLicenseCount
    }
}

# Display the group reports
$groupReports | Format-Table -AutoSize

# Disconnect from Microsoft Graph
Disconnect-MgGraph
