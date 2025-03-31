# GraphConnection.ps1
# Functions for managing Microsoft Graph connections

<#
.SYNOPSIS
    Tests if the current PowerShell session is connected to Microsoft Graph with required permissions.

.DESCRIPTION
    This function validates if the current session is connected to Microsoft Graph
    and has all the required permissions for EntraPIM module functions.

.PARAMETER ShowDetails
    When specified, shows additional connection details.

.PARAMETER IncludeApprovals
    When specified, also checks for permissions required for approval operations.

.EXAMPLE
    Test-GraphConnection -ShowDetails
    
    Tests the connection and displays additional details.

.EXAMPLE
    Test-GraphConnection -IncludeApprovals
    
    Tests the connection including permissions required for approval operations.
#>
function Test-GraphConnection {
    [CmdletBinding()]
    param(
        [switch]$ShowDetails,
        [switch]$IncludeApprovals
    )

    # The minimum required permissions for basic PIM operations
    $requiredScopes = @(
        # For PIM Group operations
        "PrivilegedEligibilitySchedule.Read.AzureADGroup",
        "PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup",
        
        # For PIM Role operations
        "RoleEligibilitySchedule.Read.Directory",
        "RoleAssignmentSchedule.ReadWrite.Directory"
    )

    # Add approval-specific permissions if needed
    if ($IncludeApprovals) {
        $requiredScopes += @(
            "PrivilegedAccess.ReadWrite.AzureAD",
            "RoleManagement.ReadWrite.Directory"
        )
    }
    
    # Check if connected to Microsoft Graph
    try {
        $context = Get-MgContext -ErrorAction Stop
        if (-not $context) {
            Write-Host "`n[ERROR] Not connected to Microsoft Graph. Please connect first with:" -ForegroundColor Red
            Write-Host "Connect-MgGraph -Scopes '$($requiredScopes -join "','")'" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "`n[ERROR] Not connected to Microsoft Graph. Please connect first with:" -ForegroundColor Red
        Write-Host "Connect-MgGraph -Scopes '$($requiredScopes -join "','")'" -ForegroundColor Yellow
        return $false
    }

    # Get current scopes
    $currentScopes = $context.Scopes

    # Check for required permissions
    $missingScopes = @()
    foreach ($scope in $requiredScopes) {
        if ($currentScopes -notcontains $scope) {
            $missingScopes += $scope
        }
    }

    # Print connection information
    Write-Host "`n=== Microsoft Graph Connection ===" -ForegroundColor Cyan
    Write-Host "Connected as: $($context.Account)" -ForegroundColor White
    Write-Host "Tenant: $($context.TenantId)" -ForegroundColor White
    
    if ($ShowDetails) {
        Write-Host "Environment: $($context.Environment)" -ForegroundColor White
        Write-Host "App: $($context.AppName) ($($context.ClientId))" -ForegroundColor White
        Write-Host "Authentication: $($context.AuthType)" -ForegroundColor White
    }

    # Permission Analysis
    if ($missingScopes.Count -gt 0) {
        Write-Host "`n[WARNING] Missing required permissions: " -ForegroundColor Red
        $missingScopes | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
        
        # Check for alternative permissions that might work
        $alternatives = @(
            "Directory.AccessAsUser.All", 
            "RoleManagement.ReadWrite.Directory",
            "PrivilegedAccess.ReadWrite.AzureADGroup"
        )
        
        $hasAlternatives = $false
        foreach ($alt in $alternatives) {
            if ($currentScopes -contains $alt) {
                $hasAlternatives = $true
                break
            }
        }
        
        if ($hasAlternatives) {
            Write-Host "`nYou have some alternative permissions that might work." -ForegroundColor Yellow
            return $true # Continue with warning
        } else {
            Write-Host "`nPlease reconnect with all required permissions:" -ForegroundColor Yellow
            Write-Host "Disconnect-MgGraph" -ForegroundColor Yellow
            Write-Host "Connect-MgGraph -Scopes '$($requiredScopes -join "','")'" -ForegroundColor Yellow
            return $false
        }
    } else {
        Write-Host "`n✓ Connected with all required permissions" -ForegroundColor Green
    }
    
    return $true
}