# Invoke-PIMActivation

## SYNOPSIS
Provides an interactive menu for managing PIM role and group assignments.

## SYNTAX

```powershell
Invoke-PIMActivation
    [[-IncludeRoles] <bool>]
    [[-IncludeGroups] <bool>]
    [[-DefaultDuration] <double>]
    [<CommonParameters>]
```

## DESCRIPTION
This function presents a menu interface for activating, deactivating, and extending PIM (Privileged Identity Management) role and group assignments. Unlike the original script, this function keeps the menu active until the user explicitly chooses to exit.

The menu provides options to:

- View active and eligible PIM role and group assignments
- Activate eligible assignments with custom duration
- Deactivate active assignments
- Extend the duration of active assignments
- Check for and process pending approval requests

## PARAMETERS

### -IncludeRoles
Include role assignments in the menu.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeGroups
Include group assignments in the menu.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultDuration
The default duration in hours for activations and extensions.

```yaml
Type: Double
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 8
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.

## INPUTS

### None

## OUTPUTS

### None

## NOTES
The function requires a valid connection to Microsoft Graph API with the following permissions:

- PrivilegedEligibilitySchedule.Read.AzureADGroup
- PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup
- RoleEligibilitySchedule.Read.Directory
- RoleAssignmentSchedule.ReadWrite.Directory

To include approvals functionality, these additional permissions are needed:

- PrivilegedAccess.ReadWrite.AzureAD
- RoleManagement.ReadWrite.Directory

## EXAMPLES

### Example 1: Open the interactive menu with all roles and groups

```powershell
Invoke-PIMActivation
```

This command opens the interactive PIM activation menu, displaying all eligible and active PIM roles and groups for the current user.

### Example 2: Open the menu with only roles

```powershell
Invoke-PIMActivation -IncludeGroups $false
```

This command opens the interactive menu but only shows role assignments (no groups).

### Example 3: Open the menu with a custom activation duration

```powershell
Invoke-PIMActivation -DefaultDuration 4
```

This command opens the interactive menu with a default activation duration of 4 hours.

## MENU OPTIONS

When the menu is displayed, you'll see the following options:

- **Numbered options (1, 2, 3...)**: Select a specific role or group to activate, deactivate, or extend
- **A**: Check for pending approvals
- **R**: Refresh the list of assignments
- **X**: Exit the menu

## RELATED LINKS

- [Get-PIMAssignments](Get-PIMAssignments.md)
- [Invoke-PIMApprovals](Invoke-PIMApprovals.md)