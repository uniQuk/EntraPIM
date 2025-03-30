# Plan Outline for Integrating PIM Approvals and Migrating Scripts to PowerShell Module

## Objective
Integrate PIM approvals functionality into the existing PIM activation script and migrate both scripts into a PowerShell module for better organization and reusability.

## Current State Analysis

### PIM-Activation.ps1
- Provides interactive menu for managing PIM roles and groups
- Allows activation, deactivation, and extension of roles/groups
- Exits after performing a single action (needs modification for persistent menu)
- Uses Microsoft Graph API for PIM operations
- Includes helper functions for error handling, payload validation, etc.

### PIM-Approvals.ps1
- Fetches pending PIM role and group approvals
- Allows approving or denying requests interactively
- Uses Microsoft Graph API for approval operations
- Contains functions for retrieving and displaying approval details

## Tasks

### 1. Set Up PowerShell Module Structure
- Create a proper module directory structure in EntraPIM folder
- Define module manifest file (EntraPIM.psd1)
- Create main module file (EntraPIM.psm1)
- Organize functions into Public and Private folders based on their scope

### 2. Refactor Common Functionality
- Extract shared functionality (Graph connection, error handling, etc.)
- Move these functions to Private folder
- Ensure all functions are properly documented

### 3. Refactor PIM-Activation Script
- Move core functions to appropriate module files
- Modify the script to include a persistent menu (loop until user chooses to exit)
- Update function calls to use the module's exported functions
- Create a wrapper cmdlet for the activation functionality

### 4. Refactor PIM-Approvals Script
- Move approval functions to appropriate module files
- Create wrapper cmdlets for approval functionality
- Ensure integration with the module's other functions

### 5. Integrate PIM Approvals into Activation Script
- Add option in the activation menu to check/process pending approvals
- Ensure approvals can be handled without exiting the main menu
- Integrate approval status checks into the activation workflow

### 6. Create Example Scripts
- Create simplified example scripts that use the module
- Demonstrate how to use individual cmdlets
- Show how to combine functionality for common scenarios

### 7. Create Documentation
- Document each public function with comment-based help
- Create markdown files for key cmdlets
- Include usage examples and parameter descriptions
- Add README with module overview and installation instructions

### 8. Package and Publish
- Finalize module manifest with proper metadata
- Test module installation and import
- Prepare for GitHub and PowerShell Gallery publication

## Module Structure

```
EntraPIM/
├── EntraPIM.psd1             # Module manifest
├── EntraPIM.psm1             # Main module file
├── Public/                   # Public (exported) functions
│   ├── Get-PIMAssignments.ps1
│   ├── Invoke-PIMActivation.ps1
│   ├── Invoke-PIMApprovals.ps1
│   └── ...
├── Private/                  # Internal functions
│   ├── GraphConnection.ps1
│   ├── PayloadBuilders.ps1
│   ├── ErrorHandlers.ps1
│   └── Utils.ps1
├── docs/                     # Documentation
│   ├── Invoke-PIMActivation.md
│   ├── Invoke-PIMApprovals.md
│   └── ...
├── examples/                 # Example scripts
│   ├── Activate-Role.ps1
│   ├── Process-Approvals.ps1
│   └── ...
└── README.md                 # Module README
```

## Required Permissions

The module will require the following Microsoft Graph permissions:
- PrivilegedEligibilitySchedule.Read.AzureADGroup
- PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup
- RoleEligibilitySchedule.Read.Directory
- RoleAssignmentSchedule.ReadWrite.Directory

For approvals functionality:
- PrivilegedAccess.ReadWrite.AzureAD
- RoleManagement.ReadWrite.Directory

## Timeline
- Week 1: Setup module structure and refactor common functionality
- Week 2: Refactor PIM-Activation script and create persistent menu
- Week 3: Refactor PIM-Approvals script and integrate with activation
- Week 4: Finalize documentation, examples, and prepare for publishing