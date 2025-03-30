@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'EntraPIM.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # ID used to uniquely identify this module
    GUID = '83d0be38-4db3-4583-a32d-c51859b158c6'
    
    # Author of this module
    Author = 'EntraPIM Team'
    
    # Company or vendor of this module
    CompanyName = 'Community'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 EntraPIM Team. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'EntraPIM is a PowerShell module that simplifies the management of Microsoft Entra Privileged Identity Management (PIM) roles and groups. It provides a streamlined interface for activating, deactivating, extending, and approving PIM assignments.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.0'
    
    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''
    
    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''
    
    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''
    
    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # ClrVersion = ''
    
    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{
            ModuleName = 'Microsoft.Graph.Authentication'
            ModuleVersion = '1.19.0'
        }
    )
    
    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Get-PIMAssignments',
        'Invoke-PIMActivation',
        'Invoke-PIMApprovals'
    )
    
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = '*'
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()
    
    # DSC resources to export from this module
    # DscResourcesToExport = @()
    
    # List of all modules packaged with this module
    # ModuleList = @()
    
    # List of all files packaged with this module
    # FileList = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Entra', 'PIM', 'PrivilegedIdentityManagement', 'Graph', 'MicrosoftEntra')
            
            # A URL to the license for this module.
            LicenseUri = 'https://github.com/YourUsername/EntraPIM/blob/main/LICENSE'
            
            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/YourUsername/EntraPIM'
            
            # A URL to an icon representing this module.
            # IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
# Version 1.0.0
- Initial release of EntraPIM module
- Support for PIM role and group management
- Interactive menu with persistent state
- Approval processing functionality
'@
            
            # Prerelease string of this module
            # Prerelease = ''
            
            # Flag to indicate whether the module requires explicit user acceptance for installation/update/save
            RequireLicenseAcceptance = $false
            
            # External dependent modules of this module
            # ExternalModuleDependencies = @()
        }
    }
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}