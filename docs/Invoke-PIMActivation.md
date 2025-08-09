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

### Bulk Activation
When multiple eligible assignments are selected using comma-separated values (e.g., "1,3,5"), the function will:
1. Prompt once for common values (duration, justification, ticket information)
2. Apply these values to all selected eligible assignments
3. Display any failed activations and offer to retry them individually with different values

This streamlines the process of activating multiple roles or groups simultaneously while handling any assignments that require different parameters.

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

### Example 4: Bulk activation workflow

```powershell
Invoke-PIMActivation
# At the menu prompt, enter: 1,2,4
# The function will detect multiple eligible assignments and prompt:
# Enter duration in hours (default: 8): 6
# Enter justification (if required): Business operations
# Enter ticket info (if required): TASK-12345
# All selected assignments will be activated with these common values
```

This example shows how to activate multiple roles/groups simultaneously with shared parameters.

## MENU OPTIONS

When the menu is displayed, you'll see the following options:

- **Numbered options (1, 2, 3...)**: Select a specific role or group to activate, deactivate, or extend
  - **Single selection**: Prompts individually for each parameter
  - **Multiple selection (comma-separated)**: For eligible assignments, prompts once for common parameters and applies them to all selected items
- **A**: Check for pending approvals
- **R**: Refresh the list of assignments
- **X**: Exit the menu

### Bulk Selection Tips
- Use comma-separated values to select multiple items: `1,3,5,7`
- When multiple eligible assignments are selected, you'll be prompted once for duration, justification, and ticket information
- If any activations fail, you'll be offered the chance to retry them individually with different values
- Mixed selections (eligible and active assignments) will process eligible items in bulk and active items individually

## RELATED LINKS

- [Get-PIMAssignments](Get-PIMAssignments.md)
- [Invoke-PIMApprovals](Invoke-PIMApprovals.md)