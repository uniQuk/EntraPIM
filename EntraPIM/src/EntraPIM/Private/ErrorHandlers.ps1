# ErrorHandlers.ps1
# Functions for handling errors in EntraPIM module

<#
.SYNOPSIS
    Extracts detailed error information from Microsoft Graph API responses.

.DESCRIPTION
    This function parses error information from Microsoft Graph API responses and
    returns a structured object with message and details.

.PARAMETER ErrorRecord
    The error record to extract details from.

.EXAMPLE
    try {
        Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/me" -Method GET
    }
    catch {
        $errorDetails = Get-ErrorDetails -ErrorRecord $_
        Write-Host $errorDetails.Message
        Write-Host $errorDetails.Details
    }
#>
function Get-ErrorDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    
    $errorDetails = @{ 
        Message = $ErrorRecord.Exception.Message
        Details = "No additional details" 
    }
    
    try {
        if ($ErrorRecord.ErrorDetails -and $ErrorRecord.ErrorDetails.Message) {
            $errorJson = $ErrorRecord.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue
            
            if ($errorJson.error) {
                $errorDetails.Details = "Code: $($errorJson.error.code)`nMessage: $($errorJson.error.message)"
                
                if ($errorJson.error.details) {
                    $errorDetails.Details += "`nAdditional details:"
                    foreach ($detail in $errorJson.error.details) {
                        $errorDetails.Details += "`n- $($detail.target): $($detail.message)"
                    }
                }
            }
        }
    }
    catch {
        # If parsing fails, just return the basic error details
    }
    
    return $errorDetails
}

<#
.SYNOPSIS
    Validates a payload against a Graph API endpoint with retry logic.

.DESCRIPTION
    This function validates a payload against a Microsoft Graph API endpoint,
    with retry logic for common validation errors like missing justification.

.PARAMETER Payload
    The hashtable containing the payload to validate.

.PARAMETER Endpoint
    The Microsoft Graph API endpoint to validate against.

.PARAMETER AttemptsLimit
    The maximum number of validation attempts before giving up.

.EXAMPLE
    $payload = @{
        "action" = "selfActivate"
        "principalId" = $userId
        "roleDefinitionId" = $roleId
        "directoryScopeId" = "/"
        "justification" = "Testing"
        "isValidationOnly" = $true
    }
    
    $validatedPayload = Test-Payload -Payload $payload -Endpoint "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests"
#>
function Test-Payload {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Payload,
        
        [Parameter(Mandatory=$true)]
        [string]$Endpoint,
        
        [Parameter()]
        [int]$AttemptsLimit = 3
    )
    
    $attempts = 0
    
    while ($attempts -lt $AttemptsLimit) {
        try {
            Write-Host "Validating request at $Endpoint..." -ForegroundColor Cyan
            $jsonPayload = $Payload | ConvertTo-Json -Depth 5
            Invoke-MgGraphRequest -Method POST -Uri $Endpoint -Body $jsonPayload -ContentType "application/json" | Out-Null
            Write-Host "Validation succeeded." -ForegroundColor Green
            return $Payload
        }
        catch {
            $attempts++
            $errorDetails = Get-ErrorDetails -ErrorRecord $_
            Write-Host "Validation failed: $($errorDetails.Message)" -ForegroundColor Red
            Write-Host $errorDetails.Details -ForegroundColor Red
            
            $errorMsg = $errorDetails.Message + " " + $errorDetails.Details
            
            if ($errorMsg -match "justification|Justification|reason") {
                $Payload.justification = Read-Host "Enter updated justification"
            }
            elseif ($errorMsg -match "ticket|Ticket|reference") {
                $Payload.ticketInfo = @{ "ticketNumber" = (Read-Host "Enter updated ticket info") }
            }
            else {
                Write-Host "Validation error encountered." -ForegroundColor Yellow
                $Payload.justification = Read-Host "Enter updated justification (if required)"
                $ticket = Read-Host "Enter ticket number (if required)"
                if ($ticket) { 
                    $Payload.ticketInfo = @{ "ticketNumber" = $ticket } 
                }
            }
        }
    }
    
    throw "Too many validation attempts. Exiting."
}