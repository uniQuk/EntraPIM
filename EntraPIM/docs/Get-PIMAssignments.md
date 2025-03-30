# Get-PIMAssignments

## SYNOPSIS
Gets the current Microsoft Entra PIM role and group assignments for the signed-in user.

## SYNTAX

```powershell
Get-PIMAssignments
    [[-IncludeRoles] <bool>]
    [[-IncludeGroups] <bool>]
    [[-IncludeActive] <bool>]
    [[-IncludeEligible] <bool>]
    [[-FilterActiveFromEligible] <bool>]
    [<CommonParameters>]
```

## DESCRIPTION
This function retrieves both active and eligible PIM (Privileged Identity Management) role and group assignments for the current user. It returns a standardized object that can be used for activation, deactivation, or extension operations.

The function allows filtering by:
- Assignment type (roles and/or groups)
- Assignment state (active and/or eligible)
- Whether to filter out eligible assignments that are already active

## PARAMETERS

### -IncludeRoles
Include role assignments in the results.

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
Include group assignments in the results.

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

### -IncludeActive
Include active assignments in the results.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeEligible
Include eligible assignments in the results.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilterActiveFromEligible
When true, filters out eligible assignments that are already active.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.

## INPUTS

### None

## OUTPUTS

### System.Object[]
Array of custom objects with the following properties:
- Type: "Role" or "Group"
- State: "Active" or "Eligible"
- Name: Display name of the role or group
- RoleDefinitionId: ID of the role definition (for roles only)
- GroupId: ID of the group (for groups only)
- StartDateTime: When the assignment became or will become active
- EndDateTime: When the assignment will expire
- Raw: The original assignment object from Graph API
- Locked: Whether the assignment is locked for modification

## NOTES
The function requires a valid connection to Microsoft Graph API with the following permissions:

- PrivilegedEligibilitySchedule.Read.AzureADGroup
- PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup
- RoleEligibilitySchedule.Read.Directory
- RoleAssignmentSchedule.ReadWrite.Directory

## EXAMPLES

### Example 1: Get all PIM assignments

```powershell
Get-PIMAssignments
```

This command gets all PIM role and group assignments (both active and eligible) for the current user.

### Example 2: Get only eligible role assignments

```powershell
Get-PIMAssignments -IncludeGroups $false -IncludeActive $false
```

This command gets only eligible role assignments for the current user.

### Example 3: Get only active group assignments

```powershell
Get-PIMAssignments -IncludeRoles $false -IncludeEligible $false
```

This command gets only active group assignments for the current user.

### Example 4: Get all assignments without filtering out duplicates

```powershell
Get-PIMAssignments -FilterActiveFromEligible $false
```

This command gets all assignments, even if they exist in both active and eligible states.

### Example 5: Process assignments using pipeline

```powershell
Get-PIMAssignments | Where-Object { $_.State -eq 'Eligible' -and $_.Type -eq 'Role' } | Format-Table Name, State, StartDateTime, EndDateTime
```

This command gets all eligible role assignments and displays them in a formatted table.

## RELATED LINKS

- [Invoke-PIMActivation](Invoke-PIMActivation.md)
- [Invoke-PIMApprovals](Invoke-PIMApprovals.md)