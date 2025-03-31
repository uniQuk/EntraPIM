# Invoke-PIMActivation.ps1
# Interactive menu for PIM role and group activation/deactivation

<#
.SYNOPSIS
    Provides an interactive menu for managing PIM role and group assignments.

.DESCRIPTION
    This function presents a menu interface for activating, deactivating, and extending
    PIM (Privileged Identity Management) role and group assignments. Unlike the original
    script, this function keeps the menu active until the user explicitly chooses to exit.
    
    The function supports bulk activation, allowing users to select multiple roles or groups 
    at once by entering a comma-separated list of menu indices (e.g., "1,3,5").

.PARAMETER IncludeRoles
    Include role assignments in the menu. Default is $true.

.PARAMETER IncludeGroups
    Include group assignments in the menu. Default is $true.

.PARAMETER DefaultDuration
    The default duration in hours for activations and extensions. Default is 8.

.EXAMPLE
    Invoke-PIMActivation
    
    Opens the interactive PIM activation menu with all roles and groups.

.EXAMPLE
    Invoke-PIMActivation -IncludeGroups $false -DefaultDuration 4
    
    Opens the interactive PIM activation menu with only roles and a default duration of 4 hours.
    
.EXAMPLE
    # Bulk activation example
    # At the menu prompt, enter "1,3,5" to select and process items 1, 3, and 5 sequentially.
#>
function Invoke-PIMActivation {
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$IncludeRoles = $true,
        
        [Parameter()]
        [bool]$IncludeGroups = $true,
        
        [Parameter()]
        [double]$DefaultDuration = 8
    )
    
    # Check Graph connection first
    if (-not (Test-GraphConnection)) {
        Write-Error "Not connected to Microsoft Graph with required permissions."
        return
    }
    
    # Query current user
    $currentUser = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/me"
    $userId = $currentUser.id
    
    # Function to process a single PIM assignment
    function Process-PIMAssignment {
        param($selectedItem, $userId, $DefaultDuration)
        
        Write-Host "`nProcessing [$($selectedItem.State) $($selectedItem.Type)] '$($selectedItem.Name)'." -ForegroundColor White
        
        # Determine action based on assignment state
        if ($selectedItem.State -eq "Eligible") {
            $action = "selfActivate"
            Write-Host "Action: Activate eligible assignment." -ForegroundColor Green
            
            # Prompt for duration and justification
            $durationInput = Read-Host "Enter duration in hours (default: $DefaultDuration)"
            $duration = if ([string]::IsNullOrEmpty($durationInput)) { $DefaultDuration } else { [double]$durationInput }
            $justification = Read-Host "Enter justification (if required)"
            $ticket = Read-Host "Enter ticket info (if required)"
            
            # Create schedule info
            $scheduleInfo = New-PIMScheduleInfo -DurationHours $duration
            
            # Build payload based on type
            if ($selectedItem.Type -eq "Role") {
                $payload = New-PIMRolePayload -UserId $userId -RoleDefinitionId $selectedItem.RoleDefinitionId `
                                             -Action $action -ScheduleInfo $scheduleInfo `
                                             -Justification $justification -TicketNumber $ticket
                $endpoint = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests"
            }
            else {
                $payload = New-PIMGroupPayload -UserId $userId -GroupId $selectedItem.GroupId `
                                              -Action $action -ScheduleInfo $scheduleInfo `
                                              -Justification $justification -TicketNumber $ticket
                $endpoint = "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests"
            }
            
            # Validate payload
            $payload.isValidationOnly = $true
            $payload = Test-Payload -Payload $payload -Endpoint $endpoint
            $payload.isValidationOnly = $false
            
            # Submit request
            try {
                $jsonPayload = $payload | ConvertTo-Json -Depth 5
                Write-Host "`nActivating $($selectedItem.Type.ToLower())..." -ForegroundColor Cyan
                $response = Invoke-MgGraphRequest -Method POST -Uri $endpoint -Body $jsonPayload -ContentType "application/json"
                Write-Host "Assignment activated successfully." -ForegroundColor Green
                
                # Display result
                Write-Host "`nResponse:" -ForegroundColor Green
                $response | Format-Table
            }
            catch {
                $errorDetails = Get-ErrorDetails -ErrorRecord $_
                Write-Host "`nError during activation:" -ForegroundColor Red
                Write-Host $errorDetails.Message -ForegroundColor Red
                Write-Host $errorDetails.Details -ForegroundColor Red
            }
        }
        elseif ($selectedItem.State -eq "Active") {
            $choice = Read-Host "Assignment is active. Would you like to Extend (E) or Deactivate (D)? (E/D)"
            
            if ($choice -match "^[Ee]") {
                if (Test-AssignmentLock $selectedItem.Raw) { 
                    Write-Host "Cannot extend: Less than 5 minutes since activation." -ForegroundColor Red
                    return $false
                }
                
                $action = "extend"
                Write-Host "Action: Extend active assignment." -ForegroundColor Green
                
                # First deactivate the current assignment
                Write-Host "`nExtending assignment: Sending deactivation request first..." -ForegroundColor Cyan
                
                if ($selectedItem.Type -eq "Role") {
                    $deactPayload = New-PIMRolePayload -UserId $userId -RoleDefinitionId $selectedItem.RoleDefinitionId -Action "selfDeactivate"
                    $endpoint = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests"
                }
                else {
                    $deactPayload = New-PIMGroupPayload -UserId $userId -GroupId $selectedItem.GroupId -Action "selfDeactivate"
                    $endpoint = "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests"
                }
                
                try {
                    $jsonDeact = $deactPayload | ConvertTo-Json -Depth 5
                    Invoke-MgGraphRequest -Method POST -Uri $endpoint -Body $jsonDeact -ContentType "application/json" | Out-Null
                    Write-Host "Deactivation succeeded." -ForegroundColor Green
                }
                catch {
                    $errorDetails = Get-ErrorDetails -ErrorRecord $_
                    Write-Host "Error during deactivation for extension:" -ForegroundColor Red
                    Write-Host $errorDetails.Message -ForegroundColor Red
                    Write-Host $errorDetails.Details -ForegroundColor Red
                    return $false
                }
                
                if (-not (Wait-ForDeactivation -Type $selectedItem.Type -Id ($selectedItem.Type -eq "Role" ? $selectedItem.RoleDefinitionId : $selectedItem.GroupId))) {
                    Write-Host "Timed out waiting for deactivation. Exiting." -ForegroundColor Red
                    return $false
                }
                
                # Now reactivate with new duration
                $durationInput = Read-Host "Enter duration in hours (default: $DefaultDuration)"
                $duration = if ([string]::IsNullOrEmpty($durationInput)) { $DefaultDuration } else { [double]$durationInput }
                $justification = Read-Host "Enter justification (if required)"
                $ticket = Read-Host "Enter ticket info (if required)"
                
                # Create schedule info
                $scheduleInfo = New-PIMScheduleInfo -DurationHours $duration
                
                # Build payload for activation after extension
                if ($selectedItem.Type -eq "Role") {
                    $payload = New-PIMRolePayload -UserId $userId -RoleDefinitionId $selectedItem.RoleDefinitionId `
                                                 -Action "selfActivate" -ScheduleInfo $scheduleInfo `
                                                 -Justification $justification -TicketNumber $ticket
                    $endpoint = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests"
                }
                else {
                    $payload = New-PIMGroupPayload -UserId $userId -GroupId $selectedItem.GroupId `
                                                  -Action "selfActivate" -ScheduleInfo $scheduleInfo `
                                                  -Justification $justification -TicketNumber $ticket
                    $endpoint = "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests"
                }
                
                # Validate payload
                $payload.isValidationOnly = $true
                $payload = Test-Payload -Payload $payload -Endpoint $endpoint
                $payload.isValidationOnly = $false
                
                # Submit request
                try {
                    $jsonPayload = $payload | ConvertTo-Json -Depth 5
                    Write-Host "`nReactivating $($selectedItem.Type.ToLower()) with extended duration..." -ForegroundColor Cyan
                    $response = Invoke-MgGraphRequest -Method POST -Uri $endpoint -Body $jsonPayload -ContentType "application/json"
                    Write-Host "Assignment extended successfully." -ForegroundColor Green
                    
                    # Display result
                    Write-Host "`nResponse:" -ForegroundColor Green
                    $response | Format-Table
                }
                catch {
                    $errorDetails = Get-ErrorDetails -ErrorRecord $_
                    Write-Host "`nError during extension:" -ForegroundColor Red
                    Write-Host $errorDetails.Message -ForegroundColor Red
                    Write-Host $errorDetails.Details -ForegroundColor Red
                    return $false
                }
            }
            elseif ($choice -match "^[Dd]") {
                if (Test-AssignmentLock $selectedItem.Raw) { 
                    Write-Host "Cannot deactivate: Less than 5 minutes since activation." -ForegroundColor Red
                    return $false
                }
                
                $action = "selfDeactivate"
                Write-Host "Action: Deactivate active assignment." -ForegroundColor Green
                
                # Build payload based on type
                if ($selectedItem.Type -eq "Role") {
                    $payload = New-PIMRolePayload -UserId $userId -RoleDefinitionId $selectedItem.RoleDefinitionId -Action $action
                    $endpoint = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests"
                }
                else {
                    $payload = New-PIMGroupPayload -UserId $userId -GroupId $selectedItem.GroupId -Action $action
                    $endpoint = "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests"
                }
                
                # Submit request
                try {
                    $jsonPayload = $payload | ConvertTo-Json -Depth 5
                    Write-Host "`nDeactivating $($selectedItem.Type.ToLower())..." -ForegroundColor Cyan
                    $response = Invoke-MgGraphRequest -Method POST -Uri $endpoint -Body $jsonPayload -ContentType "application/json"
                    Write-Host "Assignment deactivation request submitted." -ForegroundColor Green
                    
                    if (-not (Wait-ForDeactivation -Type $selectedItem.Type -Id ($selectedItem.Type -eq "Role" ? $selectedItem.RoleDefinitionId : $selectedItem.GroupId))) {
                        Write-Host "Timed out waiting for deactivation to complete." -ForegroundColor Red
                    }
                    else {
                        Write-Host "Assignment deactivated successfully." -ForegroundColor Green
                    }
                }
                catch {
                    $errorDetails = Get-ErrorDetails -ErrorRecord $_
                    Write-Host "`nError during deactivation:" -ForegroundColor Red
                    Write-Host $errorDetails.Message -ForegroundColor Red
                    Write-Host $errorDetails.Details -ForegroundColor Red
                    return $false
                }
            }
            else { 
                Write-Host "Invalid choice." -ForegroundColor Yellow
                return $false
            }
        }
        else { 
            Write-Host "Unknown assignment state." -ForegroundColor Red
            return $false
        }
        
        return $true
    }
    
    # Main menu loop - continue until user chooses to exit
    $exitRequested = $false
    
    while (-not $exitRequested) {
        Clear-Host
        Write-Host "`n=== EntraPIM Role/Group Activation Menu ===`n" -ForegroundColor Cyan
        Write-Host "Getting PIM roles and groups for user: $($currentUser.displayName) ($userId)" -ForegroundColor White
        Write-Host "Note: Recently activated roles require a 5-minute waiting period before they can be modified." -ForegroundColor Yellow
        Write-Host "TIP: You can select multiple items using comma-separated values (e.g., '1,3,5')" -ForegroundColor Green
        
        # Get current assignments
        $assignments = Get-PIMAssignments -IncludeRoles $IncludeRoles -IncludeGroups $IncludeGroups
        
        # Display assignments in a table
        Write-Host "`n=== All PIM Roles and Groups ===" -ForegroundColor Cyan
        
        $headerFormat = "{0,-6} {1,-8} {2,-35} {3,-19} {4,-19} {5,-10} {6,-8}"
        $header = $headerFormat -f "Type", "State", "Name", "Start Time", "End Time", "Status", "Action"
        Write-Host $header -ForegroundColor Green
        Write-Host ("-" * 110) -ForegroundColor Green
        
        # Build menu items
        $menuItems = @()
        $menuIndex = 1
        
        foreach ($item in $assignments) {
            $startStr = if ($item.StartDateTime) { ([datetime]$item.StartDateTime).ToString("yyyy-MM-dd HH:mm") } else { "N/A" }
            $endStr   = if ($item.EndDateTime)   { ([datetime]$item.EndDateTime).ToString("yyyy-MM-dd HH:mm") }   else { "Permanent" }
            $availability = if ($item.Locked) { "Locked" } else { "Available" }
            $ready = if ($item.Locked) {
                $baseTime = if ($item.Raw.PSObject.Properties['createdDateTime']) { 
                    [datetime]$item.Raw.createdDateTime 
                } else { 
                    [datetime]$item.StartDateTime 
                }
                $timeLeft = [math]::Ceiling(($baseTime.AddMinutes(5) - (Get-Date)).TotalMinutes)
                "Wait ${timeLeft}m"
            } else { 
                "Ready" 
            }
            
            Write-Host ($headerFormat -f $item.Type, $item.State, $item.Name.Substring(0, [Math]::Min(35, $item.Name.Length)), $startStr, $endStr, $availability, $ready)
            
            if (-not $item.Locked) {
                $item | Add-Member -NotePropertyName MenuIndex -NotePropertyValue $menuIndex -Force
                $menuItems += $item
                $menuIndex++
            }
        }
        
        # Show menu options
        Write-Host "`n=== PIM Activation/Modification Menu ===" -ForegroundColor Cyan
        Write-Host "Select one or more assignments (comma-separated, e.g., '1,3,5'):" -ForegroundColor Magenta
        $menuItems | ForEach-Object { Write-Host "$($_.MenuIndex). [$($_.State) $($_.Type)] $($_.Name)" -ForegroundColor White }
        
        # Add approval menu option if we have approvals functionality
        Write-Host "A. Check for pending approvals" -ForegroundColor Yellow
        
        # Add refresh and exit options
        Write-Host "R. Refresh assignments" -ForegroundColor Cyan
        Write-Host "X. Exit" -ForegroundColor Cyan
        
        $selection = Read-Host "`nSelect an option"
        
        # Process selection
        if ($selection -eq "X" -or $selection -eq "x") {
            $exitRequested = $true
            continue
        }
        elseif ($selection -eq "R" -or $selection -eq "r") {
            # Just refresh by continuing the loop
            continue
        }
        elseif ($selection -eq "A" -or $selection -eq "a") {
            # Check if the approvals function exists before trying to call it
            if (Get-Command -Name Invoke-PIMApprovals -ErrorAction SilentlyContinue) {
                Invoke-PIMApprovals
            }
            else {
                Write-Host "Approvals functionality not available." -ForegroundColor Yellow
                Write-Host "The Invoke-PIMApprovals function is not loaded or not found." -ForegroundColor Yellow
                Start-Sleep -Seconds 3
            }
            continue
        }
        elseif ($selection -match "^[\d,]+$") {
            # User selected one or more assignments
            # Split the selection into individual indices
            $selectedIndices = $selection -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
            
            if ($selectedIndices.Count -gt 0) {
                Write-Host "`nProcessing $($selectedIndices.Count) selected items..." -ForegroundColor Cyan
                
                foreach ($idx in $selectedIndices) {
                    $selectedItem = $menuItems | Where-Object { $_.MenuIndex -eq [int]$idx }
                    
                    if (-not $selectedItem) {
                        Write-Host "`nInvalid selection: $idx" -ForegroundColor Yellow
                        continue
                    }
                    
                    if ($selectedItem.Locked) {
                        Write-Host "`nSelection $idx is locked and cannot be modified: $($selectedItem.Name)" -ForegroundColor Red
                        continue
                    }
                    
                    # Process the selected item
                    $result = Process-PIMAssignment -selectedItem $selectedItem -userId $userId -DefaultDuration $DefaultDuration
                    
                    # If we're not on the last item, prompt before continuing
                    if ($idx -ne $selectedIndices[-1]) {
                        Write-Host "`nPress Enter to continue with next selected item..." -ForegroundColor Cyan
                        Read-Host | Out-Null
                    }
                }
                
                Write-Host "`nAll selected items processed. Press Enter to return to menu..." -ForegroundColor Green
                Read-Host | Out-Null
            }
            else {
                Write-Host "Invalid selection." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
        }
        else {
            Write-Host "Invalid selection." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
    }
    
    Write-Host "Exiting PIM Activation menu." -ForegroundColor Yellow
}