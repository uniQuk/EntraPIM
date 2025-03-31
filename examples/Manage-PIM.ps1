# Manage-PIM.ps1
# Example script that demonstrates using the EntraPIM module

<#
.SYNOPSIS
    Demonstrates how to use the EntraPIM PowerShell module.

.DESCRIPTION
    This example script shows how to connect to Microsoft Graph and use
    the EntraPIM module to manage and automate Privileged Identity Management (PIM)
    tasks such as fetching assignments, activating roles, and processing approvals.

.NOTES
    Author: uniQUk (Josh)
    Date:   March 30, 2025
#>

# Import the module if not already loaded
if (-not (Get-Module -Name EntraPIM -ErrorAction SilentlyContinue)) {
    # For development, import from the module path
    # In production, you'd use: Import-Module EntraPIM
    Import-Module "$PSScriptRoot\..\src\EntraPIM\EntraPIM.psd1" -Force
}

# Connect to Microsoft Graph with the required permissions
# Note: This will prompt for authentication if not already connected
function Connect-EntraPIM {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$IncludeApprovals
    )
    
    $requiredScopes = @(
        # For PIM Role and Group operations
        "PrivilegedEligibilitySchedule.Read.AzureADGroup",
        "PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup",
        "RoleEligibilitySchedule.Read.Directory",
        "RoleAssignmentSchedule.ReadWrite.Directory"
    )
    
    if ($IncludeApprovals) {
        $requiredScopes += @(
            "PrivilegedAccess.ReadWrite.AzureAD",
            "RoleManagement.ReadWrite.Directory"
        )
    }

    # Check if already connected with required permissions
    $connected = $false
    try {
        $context = Get-MgContext -ErrorAction Stop
        if ($context) {
            $currentScopes = $context.Scopes
            $missingScopes = @()
            foreach ($scope in $requiredScopes) {
                if ($currentScopes -notcontains $scope) {
                    $missingScopes += $scope
                }
            }
            
            if ($missingScopes.Count -eq 0) {
                $connected = $true
                Write-Host "Already connected to Microsoft Graph with required permissions." -ForegroundColor Green
            } else {
                Write-Host "Connected to Microsoft Graph but missing some required permissions." -ForegroundColor Yellow
                Write-Host "Missing permissions: $($missingScopes -join ", ")" -ForegroundColor Yellow
                Write-Host "Disconnecting and reconnecting with all required permissions..." -ForegroundColor Yellow
                Disconnect-MgGraph | Out-Null
            }
        }
    } catch {
        # Not connected
    }
    
    if (-not $connected) {
        Write-Host "Connecting to Microsoft Graph with required permissions..." -ForegroundColor Cyan
        Connect-MgGraph -Scopes $requiredScopes
    }
}

# Display a menu with options
function Show-Menu {
    Clear-Host
    Write-Host "=== EntraPIM Module Demo ===" -ForegroundColor Cyan
    Write-Host "1. List my PIM Role and Group assignments" -ForegroundColor White
    Write-Host "2. Activate a PIM Role or Group assignment (interactive)" -ForegroundColor White
    Write-Host "3. Process PIM approvals" -ForegroundColor White
    Write-Host "4. Non-interactive role activation (script example)" -ForegroundColor White
    Write-Host "0. Exit" -ForegroundColor White
    
    $choice = Read-Host "`nEnter your choice (0-4)"
    return $choice
}

# Example of non-interactive role activation
function Activate-SpecificRole {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$RoleDefinitionId,
        
        [Parameter()]
        [double]$DurationHours = 8,
        
        [Parameter()]
        [string]$Justification = "Automated activation via script",
        
        [Parameter()]
        [string]$TicketNumber
    )
    
    # Get current user
    $currentUser = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/me"
    $userId = $currentUser.id
    
    # Get all assignments
    $assignments = Get-PIMAssignments -IncludeActive $false
    
    # Find the specified role
    $targetRole = $assignments | Where-Object { 
        $_.Type -eq "Role" -and $_.RoleDefinitionId -eq $RoleDefinitionId
    }
    
    if (-not $targetRole) {
        Write-Error "Role with ID $RoleDefinitionId not found or not eligible for activation."
        return
    }
    
    Write-Host "Activating role: $($targetRole.Name)" -ForegroundColor Yellow
    
    # Create schedule info
    $scheduleInfo = @{ 
        "startDateTime" = (Get-Date).ToUniversalTime().ToString("o")
        "expiration"    = @{ 
            "type" = "afterDuration"
            "duration" = if ($DurationHours -eq [math]::Floor($DurationHours)) { 
                "PT$($DurationHours)H" 
            } else { 
                $minutes = [math]::Round($DurationHours * 60)
                "PT$($minutes)M" 
            }
        }
    }
    
    # Build payload
    $payload = @{
        "action" = "selfActivate"
        "principalId" = $userId
        "roleDefinitionId" = $RoleDefinitionId
        "directoryScopeId" = "/"
        "scheduleInfo" = $scheduleInfo
        "justification" = $Justification
    }
    
    # Add ticket info if provided
    if ($TicketNumber) {
        $payload.ticketInfo = @{ "ticketNumber" = $TicketNumber }
    }
    
    # Validate first
    $payload.isValidationOnly = $true
    $jsonPayload = $payload | ConvertTo-Json -Depth 5
    
    try {
        Write-Host "Validating request..." -ForegroundColor Cyan
        Invoke-MgGraphRequest -Method POST `
                             -Uri "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests" `
                             -Body $jsonPayload `
                             -ContentType "application/json" | Out-Null
        Write-Host "Validation successful." -ForegroundColor Green
        
        # Now send the actual request
        $payload.isValidationOnly = $false
        $jsonPayload = $payload | ConvertTo-Json -Depth 5
        
        Write-Host "Activating role..." -ForegroundColor Cyan
        $response = Invoke-MgGraphRequest -Method POST `
                                        -Uri "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests" `
                                        -Body $jsonPayload `
                                        -ContentType "application/json"
        
        Write-Host "Role activated successfully!" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Error "Failed to activate role: $_"
        return $null
    }
}

# Main script execution
try {
    # Connect to Microsoft Graph with PIM permissions
    Connect-EntraPIM -IncludeApprovals
    
    # Main menu loop
    $exit = $false
    while (-not $exit) {
        $choice = Show-Menu
        
        switch ($choice) {
            "1" {
                # List PIM assignments
                Write-Host "`nFetching your PIM role and group assignments..." -ForegroundColor Cyan
                $assignments = Get-PIMAssignments
                
                # Display assignments
                Write-Host "`nYour PIM Assignments:" -ForegroundColor Yellow
                $assignments | Format-Table -Property Type, State, Name, @{
                    Label = "Start Time"; 
                    Expression = { if ($_.StartDateTime) { ([datetime]$_.StartDateTime).ToString("yyyy-MM-dd HH:mm") } else { "N/A" } }
                }, @{
                    Label = "End Time"; 
                    Expression = { if ($_.EndDateTime) { ([datetime]$_.EndDateTime).ToString("yyyy-MM-dd HH:mm") } else { "Permanent" } }
                }
                
                Write-Host "Press any key to continue..." -ForegroundColor Cyan
                [void][System.Console]::ReadKey($true)
            }
            "2" {
                # Interactive PIM activation menu
                Invoke-PIMActivation
            }
            "3" {
                # Process PIM approvals
                Invoke-PIMApprovals
            }
            "4" {
                # Example of non-interactive role activation
                Write-Host "`nNon-interactive Role Activation Example" -ForegroundColor Cyan
                
                # First list eligible roles
                $eligibleRoles = Get-PIMAssignments -IncludeGroups $false -IncludeActive $false
                
                if ($eligibleRoles.Count -eq 0) {
                    Write-Host "No eligible roles found." -ForegroundColor Yellow
                } else {
                    Write-Host "`nYour Eligible Roles:" -ForegroundColor Yellow
                    $index = 1
                    $eligibleRoles | ForEach-Object {
                        Write-Host "$index. $($_.Name) (ID: $($_.RoleDefinitionId))" -ForegroundColor White
                        $index++
                    }
                    
                    $roleIndex = Read-Host "`nEnter the number of the role to activate (or 0 to cancel)"
                    
                    if ($roleIndex -match "^\d+$" -and [int]$roleIndex -gt 0 -and [int]$roleIndex -le $eligibleRoles.Count) {
                        $selectedRole = $eligibleRoles[[int]$roleIndex - 1]
                        
                        $duration = Read-Host "Enter activation duration in hours (default: 8)"
                        if ([string]::IsNullOrEmpty($duration)) { $duration = 8 }
                        
                        $ticket = Read-Host "Enter ticket number (optional)"
                        
                        # Activate the role
                        $params = @{
                            RoleDefinitionId = $selectedRole.RoleDefinitionId
                            DurationHours = [double]$duration
                            Justification = "Automated activation via example script"
                        }
                        
                        if (-not [string]::IsNullOrEmpty($ticket)) {
                            $params.TicketNumber = $ticket
                        }
                        
                        $result = Activate-SpecificRole @params
                        
                        if ($result) {
                            Write-Host "`nRole activation request submitted successfully." -ForegroundColor Green
                            $result | Format-List
                        }
                    } elseif ($roleIndex -ne "0") {
                        Write-Host "Invalid selection." -ForegroundColor Yellow
                    }
                }
                
                Write-Host "Press any key to continue..." -ForegroundColor Cyan
                [void][System.Console]::ReadKey($true)
            }
            "0" {
                $exit = $true
                Write-Host "Exiting..." -ForegroundColor Yellow
            }
            default {
                Write-Host "Invalid choice. Press any key to continue..." -ForegroundColor Red
                [void][System.Console]::ReadKey($true)
            }
        }
    }
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    # Uncomment if you want to disconnect after script execution
    # Disconnect-MgGraph
}