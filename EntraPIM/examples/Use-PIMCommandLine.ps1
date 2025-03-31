#!/usr/bin/env pwsh
#Requires -Version 7.0
#Requires -Modules @{ ModuleName='Microsoft.Graph.Authentication'; ModuleVersion='2.26.0' }

<#
.SYNOPSIS
    Example script showing how to use EntraPIM for command-line PIM activation scenarios.

.DESCRIPTION
    This script demonstrates various ways to use the EntraPIM module for activating 
    PIM roles and groups from the command line, using configuration files, and
    automating approval processing.

.EXAMPLE
    ./Use-PIMCommandLine.ps1

.NOTES
    You must have already installed the EntraPIM module and have appropriate
    permissions to manage PIM roles and groups.
#>

# Import EntraPIM module if not already loaded
if (-not (Get-Module -Name EntraPIM -ErrorAction SilentlyContinue)) {
    # First try to import from installed modules
    try {
        Import-Module -Name EntraPIM -ErrorAction Stop
        Write-Host "Imported EntraPIM module from installed modules" -ForegroundColor Green
    }
    catch {
        # If not installed, try to import from the relative path
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "src\EntraPIM\EntraPIM.psd1"
        
        if (Test-Path -Path $modulePath) {
            Import-Module -Name $modulePath -ErrorAction Stop
            Write-Host "Imported EntraPIM module from: $modulePath" -ForegroundColor Green
        }
        else {
            Write-Error "Could not locate EntraPIM module. Make sure it's installed or the path is correct."
            exit 1
        }
    }
}

# Connect to Microsoft Graph if not already connected
if (-not (Test-GraphConnection)) {
    try {
        Connect-MgGraph -Scopes @(
            "PrivilegedEligibilitySchedule.Read.AzureADGroup",
            "PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup",
            "RoleEligibilitySchedule.Read.Directory",
            "RoleAssignmentSchedule.ReadWrite.Directory",
            "PrivilegedAccess.ReadWrite.AzureAD",
            "RoleManagement.ReadWrite.Directory"
        )
        Write-Host "Connected to Microsoft Graph" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to connect to Microsoft Graph: $_"
        exit 1
    }
}

#region EXAMPLE 1: Creating and using a configuration file
Write-Host "`n===== EXAMPLE 1: Creating and using a configuration file =====" -ForegroundColor Yellow

# Define a custom configuration file path
$configPath = "$env:TEMP\EntraPIM.config.json"

# Let's create a configuration file with default values
$defaultConfig = @{
    DefaultJustification = "Business as usual activities"
    DefaultTicketNumber = "INC2025-0330"
    DefaultDuration = 4
}

try {
    $defaultConfig | ConvertTo-Json | Set-Content -Path $configPath
    Write-Host "Created configuration file at: $configPath" -ForegroundColor Green
    Write-Host "With default values:`n$($defaultConfig | ConvertTo-Json)" -ForegroundColor Cyan
}
catch {
    Write-Error "Failed to create configuration file: $_"
}

Write-Host "`nYou can now use New-PIMActivation with this config file using:" -ForegroundColor Magenta
Write-Host "New-PIMActivation -Type Role -ResourceId `"your-role-id`" -ConfigPath `"$configPath`"" -ForegroundColor Gray
#endregion

#region EXAMPLE 2: Getting eligible PIM assignments and activating one
Write-Host "`n===== EXAMPLE 2: Getting eligible PIM assignments and activating one =====" -ForegroundColor Yellow

# Get eligible role assignments
Write-Host "`nFetching your eligible PIM role assignments..." -ForegroundColor Cyan
$eligibleRoles = Get-PIMAssignments -IncludeActive $false -IncludeGroups $false

if ($eligibleRoles.Count -eq 0) {
    Write-Host "You don't have any eligible role assignments." -ForegroundColor Yellow
}
else {
    # Display eligible roles
    Write-Host "`nYour eligible roles:" -ForegroundColor Green
    $eligibleRoles | Format-Table -Property DisplayName, ResourceId, Type

    # Select the first eligible role for demonstration
    $roleToActivate = $eligibleRoles[0]
    Write-Host "`nWe'll use this role for demonstration:" -ForegroundColor Cyan
    Write-Host "Role: $($roleToActivate.DisplayName)" -ForegroundColor Cyan
    Write-Host "ID: $($roleToActivate.ResourceId)" -ForegroundColor Cyan
    
    # Show the command that would activate the role
    Write-Host "`nTo activate this role with saved configuration, you would run:" -ForegroundColor Magenta
    Write-Host "New-PIMActivation -Type Role -ResourceId `"$($roleToActivate.ResourceId)`" -ConfigPath `"$configPath`"" -ForegroundColor Gray
    
    # Note: We're not executing the activation to avoid making actual changes
    # If you want to actually run the activation, uncomment the next line:
    # New-PIMActivation -Type Role -ResourceId $roleToActivate.ResourceId -ConfigPath $configPath
}
#endregion

#region EXAMPLE 3: Working with future activation (scheduling)
Write-Host "`n===== EXAMPLE 3: Working with future activation (scheduling) =====" -ForegroundColor Yellow

# Calculate a time in the future for demonstration purposes
$futureTime = (Get-Date).AddDays(1).Date.AddHours(9) # Tomorrow at 9 AM

Write-Host "`nScheduling an activation for tomorrow at 9 AM:" -ForegroundColor Cyan
Write-Host "Start time: $futureTime" -ForegroundColor Cyan

# Show the command to schedule a future activation
Write-Host "`nTo schedule a future activation, you would run:" -ForegroundColor Magenta
Write-Host "New-PIMActivation -Type Role -ResourceId `"role-id`" -Justification `"Scheduled maintenance`" -TicketNumber `"CHG2025-123`" -Duration 2 -StartDateTime `"$futureTime`"" -ForegroundColor Gray

# You can also combine this with saved configuration
Write-Host "`nOr using the config file but overriding some values:" -ForegroundColor Magenta
Write-Host "New-PIMActivation -Type Role -ResourceId `"role-id`" -ConfigPath `"$configPath`" -StartDateTime `"$futureTime`" -Justification `"Scheduled maintenance`"" -ForegroundColor Gray
#endregion

#region EXAMPLE 4: Checking for and processing approvals
Write-Host "`n===== EXAMPLE 4: Checking for and processing approvals =====" -ForegroundColor Yellow

# Check for pending approvals
Write-Host "`nChecking for pending PIM approvals..." -ForegroundColor Cyan
$pendingApprovals = Get-PIMApprovals

if ($pendingApprovals.Count -eq 0) {
    Write-Host "No pending approvals found." -ForegroundColor Yellow
}
else {
    # Display pending approvals
    Write-Host "`nPending approvals:" -ForegroundColor Green
    $pendingApprovals | Format-Table -Property DisplayName, RequestorName, Justification
    
    # Show how you would process approvals automatically
    Write-Host "`nTo process all approvals automatically, run:" -ForegroundColor Magenta
    Write-Host "Invoke-PIMApprovals" -ForegroundColor Gray
    
    # For selective approval
    if ($pendingApprovals.Count -gt 0) {
        $firstApproval = $pendingApprovals[0]
        Write-Host "`nTo approve a specific request, you could filter and process it:" -ForegroundColor Magenta
        Write-Host "Get-PIMApprovals | Where-Object { `$_.RequestId -eq `"$($firstApproval.RequestId)`" } | Invoke-PIMApprovals" -ForegroundColor Gray
    }
}
#endregion

#region EXAMPLE 5: Setup an automation script with saved credentials
Write-Host "`n===== EXAMPLE 5: Setup an automation script with saved credentials =====" -ForegroundColor Yellow

# This is just a demonstration of how one could structure an automation script
$automationScript = @'
# Get credentials from secure storage (e.g., Azure KeyVault, SecretManagement)
# $credential = Get-Secret -Name "EntraPIMCredential"

# Connect to Graph silently
# Connect-MgGraph -Credential $credential

# Activate a specific role with saved configuration
# New-PIMActivation -Type Role -ResourceId "your-role-id" -ConfigPath "C:\Scripts\EntraPIM.config.json"

# Log the activation
# $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
# "[$timestamp] PIM role activated successfully" | Out-File -Append -FilePath "C:\Logs\PIM-Activations.log"
'@

Write-Host "`nSample automation script:" -ForegroundColor Cyan
Write-Host $automationScript -ForegroundColor Gray

Write-Host "`nYou could schedule this script to run at specific times using a task scheduler." -ForegroundColor Green
#endregion

#region EXAMPLE 6: Bulk activation of multiple roles
Write-Host "`n===== EXAMPLE 6: Bulk activation of multiple roles =====" -ForegroundColor Yellow

$roleIds = @(
    "11111111-1111-1111-1111-111111111111", # Example Role 1
    "22222222-2222-2222-2222-222222222222"  # Example Role 2
)

Write-Host "`nActivating multiple roles at once:" -ForegroundColor Cyan

$bulkActivationScript = @"
# Get all eligible role assignments
`$eligibleRoles = Get-PIMAssignments -IncludeActive `$false -IncludeGroups `$false

# Filter for specific roles we want to activate
`$rolesToActivate = `$eligibleRoles | Where-Object { `$_.ResourceId -in `$roleIds }

# Activate each role
foreach (`$role in `$rolesToActivate) {
    Write-Host "Activating role: `$(`$role.DisplayName)" -ForegroundColor Cyan
    New-PIMActivation -Type Role -ResourceId `$role.ResourceId -ConfigPath "$configPath"
}
"@

Write-Host "`nSample bulk activation script:" -ForegroundColor Cyan
Write-Host $bulkActivationScript -ForegroundColor Gray
#endregion

# Clean up the temporary config file
if (Test-Path -Path $configPath) {
    Remove-Item -Path $configPath -Force
    Write-Host "`nRemoved temporary configuration file: $configPath" -ForegroundColor Gray
}

Write-Host "`n===== Script Completed =====" -ForegroundColor Green
Write-Host "For more information, see the documentation at: https://github.com/YourUsername/EntraPIM" -ForegroundColor Gray