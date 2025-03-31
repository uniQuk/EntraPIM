# New-PIMActivation.ps1
# Command-line activation for PIM roles and groups with config file support

<#
.SYNOPSIS
    Activates Microsoft Entra PIM roles or groups from command line with configuration support.

.DESCRIPTION
    This function activates PIM (Privileged Identity Management) roles or groups 
    using command-line parameters or defaults from a configuration file.
    If any required parameters are missing, it will prompt for them interactively.

.PARAMETER Type
    The type of resource to activate. Valid values are 'Role' or 'Group'.

.PARAMETER ResourceId
    The ID of the role or group to activate.

.PARAMETER Justification
    The justification for the activation request.

.PARAMETER TicketNumber
    The ticket number associated with the activation request.

.PARAMETER Duration
    The duration in hours for which to activate the role or group.

.PARAMETER StartDateTime
    The start date and time for the activation. Default is the current time.

.PARAMETER ConfigPath
    Path to the configuration file. Default is "$env:USERPROFILE\EntraPIM.config.json".
    If the file doesn't exist, the function will use provided parameters or prompt for missing ones.

.PARAMETER SaveConfig
    Switch to save provided parameters to the configuration file for future use.

.EXAMPLE
    New-PIMActivation -Type Role -ResourceId "12345678-1234-1234-1234-123456789012"
    
    Activates the specified role using defaults from the config file, or prompts for missing information.

.EXAMPLE
    New-PIMActivation -Type Group -ResourceId "12345678-1234-1234-1234-123456789012" -Justification "Production issue" -TicketNumber "INC123456" -Duration 8
    
    Activates the specified group with the provided justification, ticket number, and duration.

.EXAMPLE
    New-PIMActivation -Type Role -ResourceId "12345678-1234-1234-1234-123456789012" -SaveConfig
    
    Activates the specified role and saves the provided parameters to the configuration file.
#>
function New-PIMActivation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Role', 'Group')]
        [string]$Type,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,
        
        [Parameter(Mandatory = $false)]
        [string]$Justification,
        
        [Parameter(Mandatory = $false)]
        [string]$TicketNumber,
        
        [Parameter(Mandatory = $false)]
        [int]$Duration,
        
        [Parameter(Mandatory = $false)]
        [datetime]$StartDateTime = (Get-Date),
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = "$env:USERPROFILE\EntraPIM.config.json",
        
        [Parameter(Mandatory = $false)]
        [switch]$SaveConfig
    )
    
    # Check Graph connection first
    if (-not (Test-GraphConnection)) {
        Write-Error "Not connected to Microsoft Graph with required permissions."
        return
    }
    
    # Load configuration if it exists
    $config = @{}
    if (Test-Path $ConfigPath) {
        try {
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            Write-Verbose "Loaded configuration from $ConfigPath"
        }
        catch {
            Write-Warning "Could not load configuration file: $_"
        }
    }
    
    # Use parameters or defaults from config
    $effectiveJustification = $Justification
    if ([string]::IsNullOrEmpty($effectiveJustification) -and $config.DefaultJustification) {
        $effectiveJustification = $config.DefaultJustification
    }
    
    $effectiveTicketNumber = $TicketNumber
    if ([string]::IsNullOrEmpty($effectiveTicketNumber) -and $config.DefaultTicketNumber) {
        $effectiveTicketNumber = $config.DefaultTicketNumber
    }
    
    $effectiveDuration = $Duration
    if ($effectiveDuration -eq 0 -and $config.DefaultDuration) {
        $effectiveDuration = $config.DefaultDuration
    }
    
    # Prompt for missing values interactively
    if ([string]::IsNullOrEmpty($effectiveJustification)) {
        $effectiveJustification = Read-Host -Prompt "Enter justification for activation"
    }
    
    if ([string]::IsNullOrEmpty($effectiveTicketNumber)) {
        $effectiveTicketNumber = Read-Host -Prompt "Enter ticket number for activation (press Enter to skip)"
    }
    
    if ($effectiveDuration -le 0) {
        $durationInput = Read-Host -Prompt "Enter activation duration in hours (default: 8)"
        if ([string]::IsNullOrEmpty($durationInput)) {
            $effectiveDuration = 8
        }
        else {
            $effectiveDuration = [int]$durationInput
        }
    }
    
    # Save configuration if requested
    if ($SaveConfig) {
        $newConfig = @{
            DefaultJustification = $effectiveJustification
            DefaultTicketNumber = $effectiveTicketNumber
            DefaultDuration = $effectiveDuration
        }
        
        try {
            $newConfig | ConvertTo-Json | Set-Content -Path $ConfigPath
            Write-Host "Configuration saved to $ConfigPath" -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not save configuration: $_"
        }
    }
    
    # Get current user
    $currentUser = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/me"
    $userId = $currentUser.id
    
    # Create schedule info for the activation
    $scheduleInfo = New-PIMScheduleInfo -DurationHours $effectiveDuration -StartTime $StartDateTime
    
    # Build activation payload based on resource type
    if ($Type -eq 'Role') {
        Write-Host "Activating role with ID: $ResourceId" -ForegroundColor Cyan
        $payload = New-PIMRolePayload -UserId $userId -RoleDefinitionId $ResourceId `
                                     -Action "selfActivate" -ScheduleInfo $scheduleInfo `
                                     -Justification $effectiveJustification -TicketNumber $effectiveTicketNumber
        $endpoint = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests"
    }
    else {
        Write-Host "Activating group with ID: $ResourceId" -ForegroundColor Cyan
        $payload = New-PIMGroupPayload -UserId $userId -GroupId $ResourceId `
                                      -Action "selfActivate" -ScheduleInfo $scheduleInfo `
                                      -Justification $effectiveJustification -TicketNumber $effectiveTicketNumber
        $endpoint = "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests"
    }
    
    # Validate request first
    $payload.isValidationOnly = $true
    try {
        $jsonPayload = $payload | ConvertTo-Json -Depth 5
        Write-Verbose "Validating activation request..."
        Invoke-MgGraphRequest -Method POST -Uri $endpoint -Body $jsonPayload -ContentType "application/json" | Out-Null
        Write-Verbose "Validation successful"
    }
    catch {
        $errorDetails = Get-ErrorDetails -ErrorRecord $_
        Write-Error "Validation failed: $($errorDetails.Message)"
        return
    }
    
    # Submit actual request
    $payload.isValidationOnly = $false
    try {
        $jsonPayload = $payload | ConvertTo-Json -Depth 5
        Write-Host "Submitting activation request..." -ForegroundColor Cyan
        $response = Invoke-MgGraphRequest -Method POST -Uri $endpoint -Body $jsonPayload -ContentType "application/json"
        
        # Create a nice summary object to return
        $result = [PSCustomObject]@{
            Type = $Type
            ResourceId = $ResourceId
            ResourceName = if ($Type -eq 'Role') { "Role ID: $ResourceId" } else { "Group ID: $ResourceId" }
            Status = $response.status
            StartTime = $StartDateTime
            EndTime = $StartDateTime.AddHours($effectiveDuration)
            Duration = $effectiveDuration
            Justification = $effectiveJustification
            TicketNumber = $effectiveTicketNumber
            RequestId = $response.id
        }
        
        # Try to get resource name for better display
        if ($Type -eq 'Role') {
            try {
                $roleInfo = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/directoryRoles/roleTemplateId/$ResourceId"
                $result.ResourceName = $roleInfo.displayName
            }
            catch {
                Write-Verbose "Could not retrieve role name"
            }
        }
        else {
            try {
                $groupInfo = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$ResourceId"
                $result.ResourceName = $groupInfo.displayName
            }
            catch {
                Write-Verbose "Could not retrieve group name"
            }
        }
        
        Write-Host "Activation request submitted successfully" -ForegroundColor Green
        Write-Host "Resource: $($result.ResourceName)" -ForegroundColor Green
        Write-Host "Status: $($result.Status)" -ForegroundColor Green
        Write-Host "Duration: $effectiveDuration hour(s)" -ForegroundColor Green
        
        return $result
    }
    catch {
        $errorDetails = Get-ErrorDetails -ErrorRecord $_
        Write-Error "Activation failed: $($errorDetails.Message)"
        return
    }
}