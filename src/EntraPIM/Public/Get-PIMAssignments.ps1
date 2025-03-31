# Get-PIMAssignments.ps1
# Get PIM Role and Group assignments

<#
.SYNOPSIS
    Gets the current Microsoft Entra PIM role and group assignments for the signed-in user.

.DESCRIPTION
    This function retrieves both active and eligible PIM (Privileged Identity Management)
    role and group assignments for the current user. It returns a standardized object
    that can be used for activation, deactivation, or extension operations.

.PARAMETER IncludeRoles
    Include role assignments in the results. Default is $true.

.PARAMETER IncludeGroups
    Include group assignments in the results. Default is $true.

.PARAMETER IncludeActive
    Include active assignments in the results. Default is $true.

.PARAMETER IncludeEligible
    Include eligible assignments in the results. Default is $true.

.PARAMETER FilterActiveFromEligible
    When true, filters out eligible assignments that are already active. Default is $true.

.EXAMPLE
    Get-PIMAssignments
    
    Gets all PIM role and group assignments for the current user.

.EXAMPLE
    Get-PIMAssignments -IncludeGroups $false -IncludeActive $false
    
    Gets only eligible role assignments for the current user.

.EXAMPLE
    Get-PIMAssignments | Where-Object { $_.State -eq 'Eligible' -and $_.Type -eq 'Role' }
    
    Gets only eligible role assignments for the current user.
#>
function Get-PIMAssignments {
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$IncludeRoles = $true,
        
        [Parameter()]
        [bool]$IncludeGroups = $true,
        
        [Parameter()]
        [bool]$IncludeActive = $true,
        
        [Parameter()]
        [bool]$IncludeEligible = $true,
        
        [Parameter()]
        [bool]$FilterActiveFromEligible = $true
    )
    
    # Check Graph connection first
    if (-not (Test-GraphConnection)) {
        Write-Error "Not connected to Microsoft Graph with required permissions."
        return
    }
    
    # Query current user
    $currentUser = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/me"
    $userId = $currentUser.id
    Write-Host "Getting PIM roles and groups for user: $($currentUser.displayName) ($userId)" -ForegroundColor White
    
    $processedActiveRoles = @()
    $processedEligibleRoles = @()
    $processedActiveGroups = @()
    $processedEligibleGroups = @()
    
    # Retrieve role assignments if requested
    if ($IncludeRoles) {
        if ($IncludeActive) {
            $activeRoles = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleInstances?`$filter=principalId eq '$userId'&`$expand=roleDefinition"
            $processedActiveRoles = @($activeRoles.value | ForEach-Object { 
                ConvertTo-AssignmentObject -Assignment $_ -Type "Role" -State "Active" 
            } | Where-Object { $_ })
        }
        
        if ($IncludeEligible) {
            $eligibleRoles = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/roleManagement/directory/roleEligibilityScheduleInstances?`$filter=principalId eq '$userId'&`$expand=roleDefinition"
            $processedEligibleRoles = @($eligibleRoles.value | ForEach-Object { 
                ConvertTo-AssignmentObject -Assignment $_ -Type "Role" -State "Eligible" 
            } | Where-Object { $_ })
        }
    }
    
    # Retrieve group assignments if requested
    if ($IncludeGroups) {
        if ($IncludeActive) {
            $activeGroups = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleInstances/filterByCurrentUser(on='principal')"
            $processedActiveGroups = @($activeGroups.value | ForEach-Object { 
                ConvertTo-AssignmentObject -Assignment $_ -Type "Group" -State "Active" 
            } | Where-Object { $_ })
        }
        
        if ($IncludeEligible) {
            $eligibleGroups = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/eligibilitySchedules/filterByCurrentUser(on='principal')"
            $processedEligibleGroups = @($eligibleGroups.value | ForEach-Object { 
                ConvertTo-AssignmentObject -Assignment $_ -Type "Group" -State "Eligible" 
            } | Where-Object { $_ })
        }
    }
    
    # Filter out eligible assignments that already have an active counterpart if requested
    if ($FilterActiveFromEligible -and $IncludeActive -and $IncludeEligible) {
        if ($IncludeRoles) {
            $filteredEligibleRoles = @($processedEligibleRoles | Where-Object {
                $eligible = $_
                $activeMatch = @($processedActiveRoles | Where-Object { $_.RoleDefinitionId -eq $eligible.RoleDefinitionId })
                ($activeMatch.Count -eq 0)
            })
            $processedEligibleRoles = $filteredEligibleRoles
        }
        
        if ($IncludeGroups) {
            $filteredEligibleGroups = @($processedEligibleGroups | Where-Object {
                $eligible = $_
                $activeMatch = @($processedActiveGroups | Where-Object { $_.GroupId -eq $eligible.GroupId })
                ($activeMatch.Count -eq 0)
            })
            $processedEligibleGroups = $filteredEligibleGroups
        }
    }
    
    # Combine all assignments into a single collection
    $allAssignments = @()
    if ($IncludeRoles -and $IncludeActive) { $allAssignments += $processedActiveRoles }
    if ($IncludeRoles -and $IncludeEligible) { $allAssignments += $processedEligibleRoles }
    if ($IncludeGroups -and $IncludeActive) { $allAssignments += $processedActiveGroups }
    if ($IncludeGroups -and $IncludeEligible) { $allAssignments += $processedEligibleGroups }
    
    # Return the assignments
    return $allAssignments
}