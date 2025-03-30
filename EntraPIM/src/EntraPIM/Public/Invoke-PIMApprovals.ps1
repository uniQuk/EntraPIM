# Invoke-PIMApprovals.ps1
# Process PIM role and group approval requests

<#
.SYNOPSIS
    Fetches and processes pending PIM role and group approval requests.

.DESCRIPTION
    This function retrieves pending approval requests for PIM roles and groups,
    and allows the user to interactively approve or deny these requests.

.PARAMETER ProcessRoles
    When true, processes role approval requests. Default is $true.

.PARAMETER ProcessGroups
    When true, processes group approval requests. Default is $true.

.EXAMPLE
    Invoke-PIMApprovals
    
    Checks for and processes all pending PIM role and group approval requests.

.EXAMPLE
    Invoke-PIMApprovals -ProcessGroups $false
    
    Checks for and processes only PIM role approval requests.
#>
function Invoke-PIMApprovals {
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$ProcessRoles = $true,
        
        [Parameter()]
        [bool]$ProcessGroups = $true
    )
    
    # Check Graph connection with approval permissions
    if (-not (Test-GraphConnection -IncludeApprovals)) {
        Write-Error "Not connected to Microsoft Graph with required approval permissions."
        return
    }
    
    Clear-Host
    Write-Host "`n=== Microsoft Entra PIM Approval Processing ===`n" -ForegroundColor Cyan
    
    $foundApprovals = $false
    
    # Process role approvals if requested
    if ($ProcessRoles) {
        Write-Host "`n--- Pending PIM Role Approvals ---" -ForegroundColor Magenta
        $roleApprovals = @(Get-PendingRoleApprovals)
        
        if ($roleApprovals.Count -gt 0) {
            Process-RoleApprovals -Approvals $roleApprovals
            $foundApprovals = $true
        } else {
            Write-Host "No pending role approvals found." -ForegroundColor Green
        }
    }
    
    # Process group approvals if requested
    if ($ProcessGroups) {
        Write-Host "`n--- Pending PIM Group Approvals ---" -ForegroundColor Magenta
        $groupApprovals = @(Get-PendingGroupApprovals)
        
        if ($groupApprovals.Count -gt 0) {
            Process-GroupApprovals -Approvals $groupApprovals
            $foundApprovals = $true
        } else {
            Write-Host "No pending group approvals found." -ForegroundColor Green
        }
    }
    
    # Show summary
    if (-not $foundApprovals) {
        Write-Host "`nNo pending approvals found. You're all caught up!" -ForegroundColor Green
    } else {
        Write-Host "`n✅ Processing complete." -ForegroundColor Cyan
    }
    
    Write-Host "Press Enter to continue..." -ForegroundColor Yellow
    Read-Host | Out-Null
}

<#
.SYNOPSIS
    Retrieves pending PIM role approval requests.

.DESCRIPTION
    Fetches pending role approval requests from Microsoft Graph API.

.EXAMPLE
    Get-PendingRoleApprovals
#>
function Get-PendingRoleApprovals {
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Fetching pending role approvals..." -ForegroundColor Cyan
        $apiUrl = "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignmentScheduleRequests/filterByCurrentUser(on='approver')?`$filter=status eq 'PendingApproval'"
        $response = Invoke-MgGraphRequest -Method GET -Uri $apiUrl
        return $response.value
    } 
    catch {
        $errorDetails = Get-ErrorDetails -ErrorRecord $_
        Write-Host "❌ Error fetching role approvals: $($errorDetails.Message)" -ForegroundColor Red
        return @()
    }
}

<#
.SYNOPSIS
    Retrieves pending PIM group approval requests.

.DESCRIPTION
    Fetches pending group approval requests from Microsoft Graph API.

.EXAMPLE
    Get-PendingGroupApprovals
#>
function Get-PendingGroupApprovals {
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Fetching pending group approvals..." -ForegroundColor Cyan
        $apiUrl = "https://graph.microsoft.com/beta/identityGovernance/privilegedAccess/group/assignmentScheduleRequests/filterByCurrentUser(on='approver')?`$filter=status eq 'PendingApproval'"
        $response = Invoke-MgGraphRequest -Method GET -Uri $apiUrl
        return $response.value
    } 
    catch {
        $errorDetails = Get-ErrorDetails -ErrorRecord $_
        Write-Host "❌ Error fetching group approvals: $($errorDetails.Message)" -ForegroundColor Red
        return @()
    }
}

<#
.SYNOPSIS
    Processes PIM role approval requests.

.DESCRIPTION
    Presents each pending role approval request and allows the user
    to approve, deny, or skip the request.

.PARAMETER Approvals
    The collection of approval requests to process.

.EXAMPLE
    Process-RoleApprovals -Approvals $roleApprovals
#>
function Process-RoleApprovals {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Approvals
    )
    
    # Safety check to prevent errors with empty collections
    if ($null -eq $Approvals -or $Approvals.Count -eq 0) {
        Write-Host "No pending role approvals." -ForegroundColor Green
        return
    }
    
    foreach ($item in $Approvals) {
        $approvalId = $item.approvalId
        $principalId = $item.principalId
        $roleTemplateId = $item.roleDefinitionId
        $justification = $item.justification
        $created = $item.createdDateTime
        
        $displayName = Get-UserDisplayName -ObjectId $principalId
        $roleName = Get-RoleDisplayName -RoleTemplateId $roleTemplateId
        
        Write-Host "`nRequest for role: $roleName" -ForegroundColor Yellow
        Write-Host "Requested by: $displayName ($principalId)"
        Write-Host "Justification: $justification"
        Write-Host "Created: $created"
        
        # Get stage ID
        $approvalDetails = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignmentApprovals/$approvalId"
        $stageId = $approvalDetails.id
        
        $choice = Read-Host "Approve (A), Deny (D), or Skip (S)?"
        
        switch ($choice.ToUpper()) {
            "A" {
                $inputJustification = Read-Host "Enter approval justification"
                $body = @{
                    justification = $inputJustification
                    reviewResult  = "Approve"
                } | ConvertTo-Json -Compress
                
                try {
                    Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignmentApprovals/$approvalId/steps/$stageId" `
                                          -Method PATCH -Body $body -ContentType "application/json"
                    Write-Host "✅ Approved" -ForegroundColor Green
                }
                catch {
                    $errorDetails = Get-ErrorDetails -ErrorRecord $_
                    Write-Host "❌ Error approving request: $($errorDetails.Message)" -ForegroundColor Red
                }
            }
            "D" {
                $inputJustification = Read-Host "Enter denial justification"
                $body = @{
                    justification = $inputJustification
                    reviewResult  = "Deny"
                } | ConvertTo-Json -Compress
                
                try {
                    Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignmentApprovals/$approvalId/steps/$stageId" `
                                          -Method PATCH -Body $body -ContentType "application/json"
                    Write-Host "❌ Denied" -ForegroundColor Yellow
                }
                catch {
                    $errorDetails = Get-ErrorDetails -ErrorRecord $_
                    Write-Host "❌ Error denying request: $($errorDetails.Message)" -ForegroundColor Red
                }
            }
            default {
                Write-Host "⏭️ Skipped" -ForegroundColor Cyan
            }
        }
    }
}

<#
.SYNOPSIS
    Processes PIM group approval requests.

.DESCRIPTION
    Presents each pending group approval request and allows the user
    to approve, deny, or skip the request.

.PARAMETER Approvals
    The collection of approval requests to process.

.EXAMPLE
    Process-GroupApprovals -Approvals $groupApprovals
#>
function Process-GroupApprovals {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Approvals
    )
    
    # Safety check to prevent errors with empty collections
    if ($null -eq $Approvals -or $Approvals.Count -eq 0) {
        Write-Host "No pending group approvals." -ForegroundColor Green
        return
    }
    
    foreach ($item in $Approvals) {
        $approvalId = $item.approvalId
        $principalId = $item.principalId
        $groupId = $item.groupId
        $justification = $item.justification
        $created = $item.createdDateTime
        
        $displayName = Get-UserDisplayName -ObjectId $principalId
        $groupName = Get-GroupDisplayName -GroupId $groupId
        
        Write-Host "`nRequest for group: $groupName" -ForegroundColor Yellow
        Write-Host "Requested by: $displayName ($principalId)"
        Write-Host "Justification: $justification"
        Write-Host "Created: $created"
        
        $choice = Read-Host "Approve (A), Deny (D), or Skip (S)?"
        
        switch ($choice.ToUpper()) {
            "A" {
                $inputJustification = Read-Host "Enter approval justification"
                $body = @{
                    justification = $inputJustification
                    reviewResult  = "Approve"
                } | ConvertTo-Json -Compress
                
                try {
                    Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/identityGovernance/privilegedAccess/group/assignmentApprovals/$approvalId/steps/$approvalId" `
                                          -Method PATCH -Body $body -ContentType "application/json"
                    Write-Host "✅ Approved" -ForegroundColor Green
                }
                catch {
                    $errorDetails = Get-ErrorDetails -ErrorRecord $_
                    Write-Host "❌ Error approving request: $($errorDetails.Message)" -ForegroundColor Red
                }
            }
            "D" {
                $inputJustification = Read-Host "Enter denial justification"
                $body = @{
                    justification = $inputJustification
                    reviewResult  = "Deny"
                } | ConvertTo-Json -Compress
                
                try {
                    Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/identityGovernance/privilegedAccess/group/assignmentApprovals/$approvalId/steps/$approvalId" `
                                          -Method PATCH -Body $body -ContentType "application/json"
                    Write-Host "❌ Denied" -ForegroundColor Yellow
                }
                catch {
                    $errorDetails = Get-ErrorDetails -ErrorRecord $_
                    Write-Host "❌ Error denying request: $($errorDetails.Message)" -ForegroundColor Red
                }
            }
            default {
                Write-Host "⏭️ Skipped" -ForegroundColor Cyan
            }
        }
    }
}