# Utils.ps1
# General utility functions for EntraPIM module

<#
.SYNOPSIS
    Gets the display name of a group using its ID.

.DESCRIPTION
    Retrieves the display name for a Microsoft Entra group using its group ID.

.PARAMETER GroupId
    The ID of the group to look up.

.EXAMPLE
    Get-GroupName -GroupId "12345678-1234-1234-1234-123456789012"
#>
function Get-GroupName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$GroupId
    )
    
    try {
        (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$GroupId").displayName
    }
    catch {
        return $GroupId
    }
}

<#
.SYNOPSIS
    Gets the display name of a user using their object ID.

.DESCRIPTION
    Retrieves the display name for a user using their Microsoft Entra object ID.

.PARAMETER ObjectId
    The object ID of the user to look up.

.EXAMPLE
    Get-UserDisplayName -ObjectId "12345678-1234-1234-1234-123456789012"
#>
function Get-UserDisplayName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ObjectId
    )
    
    try {
        $user = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/directoryObjects/$ObjectId" -Method GET
        return $user.displayName
    } catch {
        return "Unknown User"
    }
}

<#
.SYNOPSIS
    Gets the display name of a role using its template ID.

.DESCRIPTION
    Retrieves the display name for a Microsoft Entra role using its role template ID.

.PARAMETER RoleTemplateId
    The template ID of the role to look up.

.EXAMPLE
    Get-RoleDisplayName -RoleTemplateId "12345678-1234-1234-1234-123456789012"
#>
function Get-RoleDisplayName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$RoleTemplateId
    )
    
    try {
        $role = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/directoryRoles(roleTemplateId='$RoleTemplateId')" -Method GET
        return $role.displayName
    } catch {
        return "Unknown Role"
    }
}

<#
.SYNOPSIS
    Checks if a PIM assignment is locked for modification.

.DESCRIPTION
    Determines if a PIM role or group assignment is locked for modification.
    Assignments are typically locked for 5 minutes after activation.

.PARAMETER Item
    The assignment item to check.

.EXAMPLE
    Test-AssignmentLock -Item $assignment
#>
function Test-AssignmentLock {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $Item
    )
    
    $baseTime = if ($Item.PSObject.Properties['createdDateTime']) { 
        [datetime]$Item.createdDateTime 
    } else { 
        [datetime]$Item.startDateTime 
    }
    
    return ((Get-Date) -lt $baseTime.AddMinutes(5))
}

<#
.SYNOPSIS
    Waits for a deactivation operation to complete.

.DESCRIPTION
    Monitors a PIM role or group deactivation until it completes or times out.

.PARAMETER Type
    The type of assignment: "Role" or "Group".

.PARAMETER Id
    The ID of the role or group being deactivated.

.PARAMETER Timeout
    The maximum time to wait in seconds.

.PARAMETER Interval
    The polling interval in seconds.

.EXAMPLE
    Wait-ForDeactivation -Type "Role" -Id "12345678-1234-1234-1234-123456789012" -Timeout 30 -Interval 5
#>
function Wait-ForDeactivation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Role", "Group")]
        [string]$Type,
        
        [Parameter(Mandatory=$true)]
        [string]$Id,
        
        [Parameter()]
        [int]$Timeout = 30,
        
        [Parameter()]
        [int]$Interval = 5
    )
    
    $elapsed = 0
    
    while ($elapsed -lt $Timeout) {
        if ($Type -eq "Group") {
            $active = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleInstances/filterByCurrentUser(on='principal')").value |
                      Where-Object { $_.groupId -eq $Id }
        }
        else {
            $active = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleInstances/filterByCurrentUser(on='principal')").value |
                      Where-Object { $_.roleDefinitionId -eq $Id }
        }
        
        if (-not $active) { return $true }
        
        Write-Host "Waiting for deactivation to complete... ($elapsed seconds elapsed)" -ForegroundColor Yellow
        Start-Sleep -Seconds $Interval
        $elapsed += $Interval
    }
    
    return $false
}

<#
.SYNOPSIS
    Converts a PIM assignment to a standardized object.

.DESCRIPTION
    Creates a standardized object representation of a PIM role or group assignment.

.PARAMETER Assignment
    The raw assignment object from the Graph API.

.PARAMETER Type
    The type of assignment: "Role" or "Group".

.PARAMETER State
    The state of the assignment: "Active" or "Eligible".

.EXAMPLE
    ConvertTo-AssignmentObject -Assignment $roleAssignment -Type "Role" -State "Active"
#>
function ConvertTo-AssignmentObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object]$Assignment,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Role", "Group")]
        [string]$Type,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Active", "Eligible")]
        [string]$State
    )
    
    # For active assignments, skip if required properties are missing.
    if ($State -eq "Active") {
        if ($Type -eq "Role" -and (-not $Assignment.roleAssignmentScheduleId -or -not $Assignment.endDateTime)) { return $null }
        if ($Type -eq "Group" -and (-not $Assignment.assignmentScheduleId -or -not $Assignment.endDateTime)) { return $null }
    }
    
    $obj = [PSCustomObject]@{
        Type             = $Type
        State            = $State
        Name             = if ($Type -eq "Role") { $Assignment.roleDefinition.displayName } else { Get-GroupName $Assignment.groupId }
        RoleDefinitionId = if ($Type -eq "Role") { $Assignment.roleDefinitionId } else { $null }
        GroupId          = if ($Type -eq "Group") { $Assignment.groupId } else { $null }
        StartDateTime    = $Assignment.startDateTime
        EndDateTime      = $Assignment.endDateTime
        Raw              = $Assignment
        Locked           = $false
    }
    
    if ($State -eq "Active") { 
        $obj.Locked = Test-AssignmentLock $Assignment 
    }
    
    return $obj
}