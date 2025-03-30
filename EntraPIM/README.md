# EntraPIM - Microsoft Entra PIM PowerShell Module

EntraPIM is a PowerShell module that simplifies the management of Microsoft Entra Privileged Identity Management (PIM) roles and groups. It provides a streamlined interface for activating, deactivating, extending, and approving PIM assignments.

## Features

- **Interactive menu** for managing PIM roles and groups that persists until you choose to exit
- **Fetch and display** both active and eligible PIM role and group assignments
- **Activate eligible** role and group assignments with customizable duration
- **Extend active** role and group assignments
- **Deactivate** active role and group assignments
- **Process approvals** for pending PIM role and group requests
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

# Check for and process pending approvals
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

### Processing Approvals

```powershell
# Process all pending approvals
Invoke-PIMApprovals

# Process only role approvals
Invoke-PIMApprovals -ProcessGroups $false
```

## Available Commands

| Command | Description |
|---------|-------------|
| `Get-PIMAssignments` | Gets the current user's PIM role and group assignments |
| `Invoke-PIMActivation` | Launches the interactive PIM activation menu |
| `Invoke-PIMApprovals` | Processes pending PIM approval requests |

## Documentation

For detailed documentation of each function, please see:

- [Invoke-PIMActivation](docs/Invoke-PIMActivation.md)
- [Invoke-PIMApprovals](docs/Invoke-PIMApprovals.md)
- [Get-PIMAssignments](docs/Get-PIMAssignments.md)

Or use PowerShell's built-in help:

```powershell
Get-Help Invoke-PIMActivation -Detailed
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
