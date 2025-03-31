# New-PIMActivation

## SYNOPSIS
Activates Microsoft Entra PIM roles or groups from command line with configuration support.

## SYNTAX

```powershell
New-PIMActivation
    -Type <String>
    -ResourceId <String>
    [-Justification <String>]
    [-TicketNumber <String>]
    [-Duration <Int32>]
    [-StartDateTime <DateTime>]
    [-ConfigPath <String>]
    [-SaveConfig]
    [<CommonParameters>]
```

## DESCRIPTION
This function activates PIM (Privileged Identity Management) roles or groups using command-line parameters or defaults from a configuration file. If any required parameters are missing, it will prompt for them interactively.

The function provides several key features:
- Command-line activation without the interactive menu
- Configuration file support for storing defaults
- Interactive prompts for missing required information
- Support for both role and group activation
- Customizable activation duration and start time

## PARAMETERS

### -Type
The type of resource to activate. Valid values are 'Role' or 'Group'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourceId
The ID of the role or group to activate.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Justification
The justification for the activation request.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TicketNumber
The ticket number associated with the activation request.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Duration
The duration in hours for which to activate the role or group.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartDateTime
The start date and time for the activation. Default is the current time.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Current Time
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigPath
Path to the configuration file. Default is "$env:USERPROFILE\EntraPIM.config.json".
If the file doesn't exist, the function will use provided parameters or prompt for missing ones.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: "$env:USERPROFILE\EntraPIM.config.json"
Accept pipeline input: False
Accept wildcard characters: False
```

### -SaveConfig
Switch to save provided parameters to the configuration file for future use.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.

## INPUTS

### None

## OUTPUTS

### System.Object
Returns a custom object with details about the activation request including:
- Type: Resource type (Role or Group)
- ResourceId: The ID of the resource
- ResourceName: The display name of the resource (if available)
- Status: The status of the activation request
- StartTime: When the activation starts
- EndTime: When the activation ends
- Duration: Duration in hours
- Justification: The provided justification
- TicketNumber: The provided ticket number
- RequestId: The ID of the submitted request

## NOTES
The function requires a valid connection to Microsoft Graph API with the following permissions:

- PrivilegedEligibilitySchedule.Read.AzureADGroup
- PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup
- RoleEligibilitySchedule.Read.Directory
- RoleAssignmentSchedule.ReadWrite.Directory

## EXAMPLES

### Example 1: Activate a role with default settings
```powershell
New-PIMActivation -Type Role -ResourceId "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
```

This command activates the specified role using defaults from the configuration file, or prompts for missing information if needed.

### Example 2: Activate a group with specific parameters
```powershell
New-PIMActivation -Type Group -ResourceId "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3" -Justification "Production issue" -TicketNumber "INC123456" -Duration 8
```

This command activates the specified group with the provided justification, ticket number, and an 8-hour duration.

### Example 3: Activate a role and save settings for future use
```powershell
New-PIMActivation -Type Role -ResourceId "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3" -Justification "Standard access" -Duration 4 -SaveConfig
```

This command activates the specified role and saves the justification and duration to the configuration file for future use.

### Example 4: Schedule a future role activation
```powershell
$tomorrow = (Get-Date).AddDays(1).Date.AddHours(9) # Tomorrow at 9 AM
New-PIMActivation -Type Role -ResourceId "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3" -StartDateTime $tomorrow -Duration 8 -Justification "Planned maintenance"
```

This command schedules the activation of the specified role to begin tomorrow at 9 AM for an 8-hour duration.

### Example 5: Use a custom config file location
```powershell
New-PIMActivation -Type Role -ResourceId "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3" -ConfigPath "C:\PIMConfigs\team-config.json"
```

This command activates the specified role using settings from a custom configuration file location.

## RELATED LINKS

- [Get-PIMAssignments](Get-PIMAssignments.md)
- [Invoke-PIMActivation](Invoke-PIMActivation.md)
- [Invoke-PIMApprovals](Invoke-PIMApprovals.md)