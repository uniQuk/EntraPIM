# EntraPIM - Microsoft Entra PIM PowerShell Module

EntraPIM is a PowerShell module that simplifies the management of Microsoft Entra Privileged Identity Management (PIM) roles and groups. It provides a streamlined interface for activating, deactivating, extending, and approving PIM assignments.

## Features

- **Interactive menu** for managing PIM roles and groups that persists until you choose to exit
- **Fetch and display** both active and eligible PIM role and group assignments
- **Activate eligible** role and group assignments with customizable duration
- **Extend active** role and group assignments
- **Deactivate** active role and group assignments
- **Process approvals** for pending PIM role and group requests
- **Command-line activation** with configuration file support for quick activation without the menu
- **Query approval requests** to get information about pending approvals
- **Scriptable functions** for automation scenarios
- **Comprehensive error handling** with detailed error information

## Installation

### From PowerShell Gallery (Recommended)

```powershell
Install-Module -Name EntraPIM
```

### From GitHub

```powershell
# Clone the repository
git clone https://github.com/YourUsername/EntraPIM.git

# Import the module
Import-Module .\EntraPIM\src\EntraPIM\EntraPIM.psd1
```

## Requirements

- PowerShell 7.x or newer
- Microsoft.Graph.Authentication module (installed automatically if using Install-Module)
- Microsoft Graph API access with the following permissions:
  - **For basic functionality**:
    - PrivilegedEligibilitySchedule.Read.AzureADGroup
    - PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup
    - RoleEligibilitySchedule.Read.Directory
    - RoleAssignmentSchedule.ReadWrite.Directory
  - **For approval functionality**:
    - PrivilegedAccess.ReadWrite.AzureAD
    - RoleManagement.ReadWrite.Directory

## Quick Start

```powershell
# Import the module
Import-Module EntraPIM

# Connect to Microsoft Graph with required permissions
Connect-MgGraph -Scopes "PrivilegedEligibilitySchedule.Read.AzureADGroup","PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup","RoleEligibilitySchedule.Read.Directory","RoleAssignmentSchedule.ReadWrite.Directory"

# Get your PIM assignments
Get-PIMAssignments

# Launch the interactive PIM activation menu
Invoke-PIMActivation

# Quick activate a role with command-line activation
New-PIMActivation -Type Role -ResourceId "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3" -Justification "Emergency access"

# Check for pending approvals
Get-PIMApprovals

# Process pending approvals
Invoke-PIMApprovals
```

## Usage Examples

### Listing PIM Assignments

```powershell
# Get all assignments (both roles and groups, active and eligible)
Get-PIMAssignments

# Get only eligible role assignments
Get-PIMAssignments -IncludeGroups $false -IncludeActive $false

# Get only active group assignments
Get-PIMAssignments -IncludeRoles $false -IncludeEligible $false
```

### Using the Interactive Menu

```powershell
# Launch the full interactive menu
Invoke-PIMActivation

# Launch menu with only roles (no groups)
Invoke-PIMActivation -IncludeGroups $false

# Launch menu with a custom default duration
Invoke-PIMActivation -DefaultDuration 4
```

### Command-Line Activation

```powershell
# Activate a role using command line, with prompts for missing information
New-PIMActivation -Type Role -ResourceId "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"

# Activate with all details specified (no prompts)
New-PIMActivation -Type Group -ResourceId "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3" -Justification "Production support" -TicketNumber "INC12345" -Duration 8

# Save preferences for future activations
New-PIMActivation -Type Role -ResourceId "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3" -Justification "Standard access" -Duration 4 -SaveConfig
```

### Working with Approvals

```powershell
# Get pending approval requests
Get-PIMApprovals

# Get only role approval requests
Get-PIMApprovals -IncludeGroups $false

# Process all pending approvals
Invoke-PIMApprovals

# Process only role approvals
Invoke-PIMApprovals -ProcessGroups $false
```

## Available Commands

| Command | Description |
|---------|-------------|
| `Get-PIMAssignments` | Gets the current user's PIM role and group assignments |
| `Get-PIMApprovals` | Gets pending PIM approval requests that the user can approve |
| `Invoke-PIMActivation` | Launches the interactive PIM activation menu |
| `Invoke-PIMApprovals` | Processes pending PIM approval requests |
| `New-PIMActivation` | Activates PIM roles or groups with command-line parameters and configuration support |

## Documentation

For detailed documentation of each function, please see:

- [Get-PIMAssignments](docs/Get-PIMAssignments.md)
- [Get-PIMApprovals](docs/Get-PIMApprovals.md)
- [Invoke-PIMActivation](docs/Invoke-PIMActivation.md)
- [Invoke-PIMApprovals](docs/Invoke-PIMApprovals.md)
- [New-PIMActivation](docs/New-PIMActivation.md)

Or use PowerShell's built-in help:

```powershell
Get-Help New-PIMActivation -Detailed
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This module is not officially associated with Microsoft. It is a community-developed tool to simplify Microsoft Entra Privileged Identity Management operations. Microsoft Entra is a trademark of Microsoft Corporation.
