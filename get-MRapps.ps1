# Get the list of Enterprise applications in same format as downloading it via Azure portal
Select-MgProfile beta

$Sp = Get-MgServicePrincipal -PageSize 999 -All

$Props = @(
    "Id",
    "DisplayName",
    "AppId",
    @{n = "CreatedDateTime"; e = { $_.AdditionalProperties.createdDateTime } },
    @{n = "applicationType"; e = { $types = @(); if ($_.AppOwnerOrganizationId -eq "f8cdef31-a31e-4b4a-93e4-5f571e91255a") { $types += "Microsoft Application" }; if ($_.servicePrincipalType -eq "ManagedIdentity") { $types += "Managed Identity" }; if ($_.Tags -ccontains "WindowsAzureActiveDirectoryIntegratedApp") { $types += "Enterprise Applications" }; return $types -join " & " } },
    "accountEnabled",
    @{n = "applicationVisibility"; e = { if ($_.Tags -ccontains "HideApp") { "Hidden" }else { "Visible" } } },
    @{n = "assignmentRequired"; e = { $_.appRoleAssignmentRequired } },
    @{n = "isAppProxy"; e = { $_.Tags -ccontains "WindowsAzureActiveDirectoryOnPremApp" } }
)

$Sp | Select-Object $Props | ConvertTo-Csv -NoTypeInformation | Out-File -Encoding UTF8 -FilePath EnterpriseAppsList.csv