# Get-PIMApprovals.ps1
# Get PIM Role and Group approval requests

<#
.SYNOPSIS
    Gets pending Microsoft Entra PIM approval requests.

.DESCRIPTION
    This function retrieves pending PIM (Privileged Identity Management) approval requests
    for both roles and groups. It can filter requests by type, status, and approval type.

.PARAMETER IncludeRoles
    Include role approval requests in the results. Default is $true.

.PARAMETER IncludeGroups
    Include group approval requests in the results. Default is $true.

.PARAMETER FilterStatus
    Filter requests by status. Allowed values are 'Pending', 'Approved', 'Denied', 'Canceled', and 'Expired'.
    Default is 'Pending' to show only pending requests awaiting approval.

.PARAMETER ApproverFilter
    Filter requests by approver type. Allowed values are 'All', 'PendingMyApproval', 'MyRequests'.
    Default is 'PendingMyApproval' to show only requests that the current user can approve.

.EXAMPLE
    Get-PIMApprovals
    
    Gets all pending PIM approval requests that require the current user's approval.

.EXAMPLE
    Get-PIMApprovals -IncludeGroups $false
    
    Gets only pending role approval requests that require the current user's approval.

.EXAMPLE
    Get-PIMApprovals -ApproverFilter 'MyRequests' -FilterStatus 'All'
    
    Gets all approval requests created by the current user regardless of status.
#>
function Get-PIMApprovals {
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$IncludeRoles = $true,
        
        [Parameter()]
        [bool]$IncludeGroups = $true,
        
        [Parameter()]
        [ValidateSet('All', 'Pending', 'Approved', 'Denied', 'Canceled', 'Expired')]
        [string]$FilterStatus = 'Pending',
        
        [Parameter()]
        [ValidateSet('All', 'PendingMyApproval', 'MyRequests')]
        [string]$ApproverFilter = 'PendingMyApproval'
    )
    
    # Check Graph connection first
    if (-not (Test-GraphConnection)) {
        Write-Error "Not connected to Microsoft Graph with required permissions."
        return
    }
    
    # Query current user
    $currentUser = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/me"
    $userId = $currentUser.id
    Write-Host "Getting PIM approval requests for user: $($currentUser.displayName) ($userId)" -ForegroundColor White
    
    $processedRoleApprovals = @()
    $processedGroupApprovals = @()
    
    # Build filter string for status
    $statusFilter = if ($FilterStatus -ne 'All') {
        "status eq 'Pending'"
    } else {
        ""
    }
    
    # Retrieve role approval requests if requested
    if ($IncludeRoles) {
        try {
            $roleRequestsUrl = if ($ApproverFilter -eq 'PendingMyApproval') {
                "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests?`$filter=status eq 'PendingApproval' and filterByCurrentUser(on='approver')"
            } elseif ($ApproverFilter -eq 'MyRequests') {
                "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests?`$filter=principalId eq '$userId'"
            } else {
                "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests"
            }
            
            # Add status filter if specified and not already included
            if ($FilterStatus -ne 'All' -and $ApproverFilter -ne 'PendingMyApproval') {
                $roleRequestsUrl += if ($roleRequestsUrl.Contains('?$filter=')) {
                    " and status eq '$FilterStatus'"
                } else {
                    "?`$filter=status eq '$FilterStatus'"
                }
            }
            
            # Add expansion to include role definition details
            $roleRequestsUrl += if ($roleRequestsUrl.Contains('?')) {
                "&`$expand=roleDefinition"
            } else {
                "?`$expand=roleDefinition"
            }
            
            $roleRequests = Invoke-MgGraphRequest -Method GET -Uri $roleRequestsUrl
            
            if ($roleRequests -and $roleRequests.value) {
                $processedRoleApprovals = @($roleRequests.value | ForEach-Object {
                    ConvertTo-ApprovalObject -ApprovalRequest $_ -Type "Role"
                } | Where-Object { $_ })
            }
        }
        catch {
            Write-Warning "Error retrieving role approvals: $_"
        }
    }
    
    # Retrieve group approval requests if requested
    if ($IncludeGroups) {
        try {
            $groupRequestsUrl = if ($ApproverFilter -eq 'PendingMyApproval') {
                "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests?`$filter=status eq 'PendingApproval' and filterByCurrentUser(on='approver')"
            } elseif ($ApproverFilter -eq 'MyRequests') {
                "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests?`$filter=principalId eq '$userId'"
            } else {
                "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests"
            }
            
            # Add status filter if specified and not already included
            if ($FilterStatus -ne 'All' -and $ApproverFilter -ne 'PendingMyApproval') {
                $groupRequestsUrl += if ($groupRequestsUrl.Contains('?$filter=')) {
                    " and status eq '$FilterStatus'"
                } else {
                    "?`$filter=status eq '$FilterStatus'"
                }
            }
            
            $groupRequests = Invoke-MgGraphRequest -Method GET -Uri $groupRequestsUrl
            
            if ($groupRequests -and $groupRequests.value) {
                # Get group information for each group ID
                $groupIds = @($groupRequests.value | ForEach-Object { $_.groupId } | Select-Object -Unique)
                $groupInfo = @{}
                
                foreach ($groupId in $groupIds) {
                    try {
                        $groupDetails = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$groupId"
                        $groupInfo[$groupId] = $groupDetails
                    }
                    catch {
                        Write-Verbose "Could not get details for group $groupId"
                    }
                }
                
                $processedGroupApprovals = @($groupRequests.value | ForEach-Object {
                    $group = $groupInfo[$_.groupId]
                    ConvertTo-ApprovalObject -ApprovalRequest $_ -Type "Group" -GroupInfo $group
                } | Where-Object { $_ })
            }
        }
        catch {
            Write-Warning "Error retrieving group approvals: $_"
        }
    }
    
    # Combine all approval requests into a single collection
    $allApprovals = @()
    if ($IncludeRoles) { $allApprovals += $processedRoleApprovals }
    if ($IncludeGroups) { $allApprovals += $processedGroupApprovals }
    
    # Return the approval requests
    return $allApprovals
}

<#
.SYNOPSIS
    Internal function to convert an approval request to a standardized object.

.DESCRIPTION
    This function converts a raw approval request object from the Graph API to a standardized object
    that can be used for approval operations.

.PARAMETER ApprovalRequest
    The raw approval request object from the Graph API.

.PARAMETER Type
    The type of the approval request, either "Role" or "Group".

.PARAMETER GroupInfo
    For group approvals, the group information object.

.EXAMPLE
    ConvertTo-ApprovalObject -ApprovalRequest $request -Type "Role"
#>
function ConvertTo-ApprovalObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSObject]$ApprovalRequest,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Role", "Group")]
        [string]$Type,
        
        [Parameter(Mandatory=$false)]
        [PSObject]$GroupInfo
    )
    
    if (-not $ApprovalRequest) {
        return $null
    }
    
    $result = [PSCustomObject]@{
        Id = $ApprovalRequest.id
        Type = $Type
        RequestorId = $ApprovalRequest.principalId
        RequestorName = $null
        ResourceId = if ($Type -eq "Role") { $ApprovalRequest.roleDefinitionId } else { $ApprovalRequest.groupId }
        ResourceName = if ($Type -eq "Role") { $ApprovalRequest.roleDefinition.displayName } else { $GroupInfo.displayName }
        Status = $ApprovalRequest.status
        Schedule = if ($ApprovalRequest.schedule) { $ApprovalRequest.schedule } else { $null }
        StartDateTime = if ($ApprovalRequest.schedule.startDateTime) { $ApprovalRequest.schedule.startDateTime } else { $null }
        EndDateTime = if ($ApprovalRequest.schedule.endDateTime) { $ApprovalRequest.schedule.endDateTime } else { $null }
        Duration = if ($ApprovalRequest.schedule.startDateTime -and $ApprovalRequest.schedule.endDateTime) {
            [math]::Ceiling(([datetime]$ApprovalRequest.schedule.endDateTime - [datetime]$ApprovalRequest.schedule.startDateTime).TotalHours)
        } else { 0 }
        Justification = $ApprovalRequest.justification
        TicketNumber = if ($ApprovalRequest.ticketInfo -and $ApprovalRequest.ticketInfo.ticketNumber) {
            $ApprovalRequest.ticketInfo.ticketNumber
        } else { $null }
        CreatedDateTime = $ApprovalRequest.createdDateTime
        Action = $ApprovalRequest.action
        ApprovalStage = if ($ApprovalRequest.customData -and $ApprovalRequest.customData.approvalStage) {
            $ApprovalRequest.customData.approvalStage
        } else { 1 }
        Raw = $ApprovalRequest
    }
    
    # Try to get requestor name
    try {
        $requestor = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$($ApprovalRequest.principalId)"
        $result.RequestorName = $requestor.displayName
    }
    catch {
        Write-Verbose "Could not get requestor name"
    }
    
    return $result
}