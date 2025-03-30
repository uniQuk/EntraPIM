# Test-ModuleInstallation.ps1
# Script to test the installation and basic functionality of the EntraPIM module

<#
.SYNOPSIS
    Tests the installation and basic functionality of the EntraPIM module.

.DESCRIPTION
    This script tests whether the EntraPIM module can be properly imported
    and its functions can be accessed. It does not require an actual connection
    to Microsoft Graph, but simply verifies that the module structure is correct.

.NOTES
    Author: EntraPIM Team
    Date:   March 30, 2025
#>

# Define the path to the module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "src\EntraPIM"

Write-Host "=== EntraPIM Module Installation Test ===" -ForegroundColor Cyan
Write-Host "Testing module at path: $modulePath" -ForegroundColor White

# Test 1: Check if the module directory exists
Write-Host "`nTest 1: Checking if module directory exists..." -ForegroundColor Yellow
if (Test-Path -Path $modulePath) {
    Write-Host "✅ Module directory found." -ForegroundColor Green
} else {
    Write-Host "❌ Module directory not found at: $modulePath" -ForegroundColor Red
    exit
}

# Test 2: Check if the module manifest exists
Write-Host "`nTest 2: Checking if module manifest exists..." -ForegroundColor Yellow
$manifestPath = Join-Path -Path $modulePath -ChildPath "EntraPIM.psd1"
if (Test-Path -Path $manifestPath) {
    Write-Host "✅ Module manifest found." -ForegroundColor Green
} else {
    Write-Host "❌ Module manifest not found at: $manifestPath" -ForegroundColor Red
    exit
}

# Test 3: Check if the module can be imported
Write-Host "`nTest 3: Testing module import..." -ForegroundColor Yellow
try {
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
    Write-Host "✅ Module imported successfully." -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to import module: $_" -ForegroundColor Red
    exit
}

# Test 4: Check if the exported functions are available
Write-Host "`nTest 4: Checking exported functions..." -ForegroundColor Yellow
$expectedFunctions = @(
    "Get-PIMAssignments",
    "Invoke-PIMActivation",
    "Invoke-PIMApprovals"
)

$exportedCommands = Get-Command -Module EntraPIM

foreach ($function in $expectedFunctions) {
    if ($exportedCommands.Name -contains $function) {
        Write-Host "✅ Function found: $function" -ForegroundColor Green
    } else {
        Write-Host "❌ Function not found: $function" -ForegroundColor Red
    }
}

# Test 5: Check if help is available for the functions
Write-Host "`nTest 5: Checking help documentation..." -ForegroundColor Yellow
foreach ($function in $expectedFunctions) {
    $help = Get-Help -Name $function -ErrorAction SilentlyContinue
    if ($help.Description) {
        Write-Host "✅ Help available for: $function" -ForegroundColor Green
    } else {
        Write-Host "❌ Help not found for: $function" -ForegroundColor Red
    }
}

# Final summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "EntraPIM module structure verified." -ForegroundColor Green
Write-Host "To use the module, connect to Microsoft Graph with:" -ForegroundColor White
Write-Host "Connect-MgGraph -Scopes 'PrivilegedEligibilitySchedule.Read.AzureADGroup','PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup','RoleEligibilitySchedule.Read.Directory','RoleAssignmentSchedule.ReadWrite.Directory'" -ForegroundColor Yellow

# Clean up by removing the module
Remove-Module -Name EntraPIM -ErrorAction SilentlyContinue