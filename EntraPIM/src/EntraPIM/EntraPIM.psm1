# EntraPIM.psm1
# Main module file that imports all functions

#Requires -Version 5.1
#Requires -Modules @{ ModuleName="Microsoft.Graph.Authentication"; ModuleVersion="1.9.0" }

# Get the module directory
$ModuleRoot = $PSScriptRoot

# Initialize arrays to store exported and internal functions
$ExportedFunctions = @()
$InternalFunctions = @()

# Import Private (internal) functions first
$PrivateFunctions = @(Get-ChildItem -Path "$ModuleRoot\Private\*.ps1" -Recurse -ErrorAction SilentlyContinue)
foreach ($function in $PrivateFunctions) {
    try {
        . $function.FullName
        $InternalFunctions += $function.BaseName
        Write-Verbose "Imported private function: $($function.BaseName)"
    }
    catch {
        Write-Error "Failed to import private function $($function.FullName): $_"
    }
}

# Import Public (exported) functions
$PublicFunctions = @(Get-ChildItem -Path "$ModuleRoot\Public\*.ps1" -Recurse -ErrorAction SilentlyContinue)
foreach ($function in $PublicFunctions) {
    try {
        . $function.FullName
        $ExportedFunctions += $function.BaseName
        Write-Verbose "Imported public function: $($function.BaseName)"
    }
    catch {
        Write-Error "Failed to import public function $($function.FullName): $_"
    }
}

# Export the public functions
Export-ModuleMember -Function $ExportedFunctions

# Module initialization code
Write-Verbose "EntraPIM module loaded. Use Get-PIMAssignments, Invoke-PIMActivation, or Invoke-PIMApprovals to get started."