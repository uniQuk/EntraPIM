# PayloadBuilders.ps1
# Functions for building payloads for PIM operations

<#
.SYNOPSIS
    Builds a payload for a PIM role request.

.DESCRIPTION
    Creates a structured payload for PIM role activation, deactivation, or extension requests.

.PARAMETER UserId
    The ID of the user making the request.

.PARAMETER RoleDefinitionId
    The ID of the role definition.

.PARAMETER Action
    The action to perform: 'selfActivate', 'selfDeactivate', or 'extend'.

.PARAMETER ScheduleInfo
    Optional schedule information for activation or extension.

.PARAMETER Justification
    Optional justification for the request.

.PARAMETER TicketNumber
    Optional ticket number for the request.

.EXAMPLE
    $scheduleInfo = @{
        startDateTime = (Get-Date).ToUniversalTime().ToString("o")
        expiration = @{ 
            type = "afterDuration"
            duration = "PT8H" 
        }
    }
    
    New-PIMRolePayload -UserId "12345678-1234-1234-1234-123456789012" `
                      -RoleDefinitionId "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3" `
                      -Action "selfActivate" `
                      -ScheduleInfo $scheduleInfo `
                      -Justification "Emergency access required"
#>
function New-PIMRolePayload {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$UserId,
        
        [Parameter(Mandatory=$true)]
        [string]$RoleDefinitionId,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("selfActivate", "selfDeactivate", "extend")]
        [string]$Action,
        
        [Parameter()]
        [hashtable]$ScheduleInfo,
        
        [Parameter()]
        [string]$Justification,
        
        [Parameter()]
        [string]$TicketNumber
    )
    
    $payload = @{
        "action" = $Action
        "principalId" = $UserId
        "roleDefinitionId" = $RoleDefinitionId
        "directoryScopeId" = "/"
    }
    
    # Add schedule info for activation or extension
    if ($Action -in @("selfActivate", "extend") -and $ScheduleInfo) {
        $payload.scheduleInfo = $ScheduleInfo
    }
    
    # Add justification if provided
    if ($Justification) {
        $payload.justification = $Justification
    }
    
    # Add ticket info if provided
    if ($TicketNumber) {
        $payload.ticketInfo = @{ "ticketNumber" = $TicketNumber }
    }
    
    return $payload
}

<#
.SYNOPSIS
    Builds a payload for a PIM group request.

.DESCRIPTION
    Creates a structured payload for PIM group activation, deactivation, or extension requests.

.PARAMETER UserId
    The ID of the user making the request.

.PARAMETER GroupId
    The ID of the group.

.PARAMETER Action
    The action to perform: 'selfActivate', 'selfDeactivate', or 'extend'.

.PARAMETER ScheduleInfo
    Optional schedule information for activation or extension.

.PARAMETER Justification
    Optional justification for the request.

.PARAMETER TicketNumber
    Optional ticket number for the request.

.EXAMPLE
    $scheduleInfo = @{
        startDateTime = (Get-Date).ToUniversalTime().ToString("o")
        expiration = @{ 
            type = "afterDuration"
            duration = "PT8H" 
        }
    }
    
    New-PIMGroupPayload -UserId "12345678-1234-1234-1234-123456789012" `
                       -GroupId "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3" `
                       -Action "selfActivate" `
                       -ScheduleInfo $scheduleInfo `
                       -Justification "Emergency access required"
#>
function New-PIMGroupPayload {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$UserId,
        
        [Parameter(Mandatory=$true)]
        [string]$GroupId,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("selfActivate", "selfDeactivate", "extend")]
        [string]$Action,
        
        [Parameter()]
        [hashtable]$ScheduleInfo,
        
        [Parameter()]
        [string]$Justification,
        
        [Parameter()]
        [string]$TicketNumber
    )
    
    $payload = @{
        "action" = $Action
        "principalId" = $UserId
        "accessId" = "member"
        "groupId" = $GroupId
    }
    
    # Add schedule info for activation or extension
    if ($Action -in @("selfActivate", "extend") -and $ScheduleInfo) {
        $payload.scheduleInfo = $ScheduleInfo
    }
    
    # Add justification if provided
    if ($Justification) {
        $payload.justification = $Justification
    }
    
    # Add ticket info if provided
    if ($TicketNumber) {
        $payload.ticketInfo = @{ "ticketNumber" = $TicketNumber }
    }
    
    return $payload
}

<#
.SYNOPSIS
    Creates a schedule info object for PIM requests.

.DESCRIPTION
    Builds a schedule info object with start time and expiration for PIM activation requests.

.PARAMETER DurationHours
    The duration in hours for the activation.

.EXAMPLE
    New-PIMScheduleInfo -DurationHours 8
#>
function New-PIMScheduleInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [double]$DurationHours
    )
    
    if ($DurationHours -eq [math]::Floor($DurationHours)) { 
        $durationIso = "PT$($DurationHours)H" 
    } else { 
        $minutes = [math]::Round($DurationHours * 60)
        $durationIso = "PT$($minutes)M" 
    }
    
    return @{ 
        "startDateTime" = (Get-Date).ToUniversalTime().ToString("o")
        "expiration" = @{ 
            "type" = "afterDuration"
            "duration" = $durationIso 
        }
    }
}