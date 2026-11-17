<#
    Loads every function under Functions/ (one function per file) and exports them all.
    Scripts import it with:
        Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
#>
Set-StrictMode -Version Latest

foreach ($file in Get-ChildItem -Path (Join-Path $PSScriptRoot 'Functions') -Filter '*.ps1' -Recurse) {
    . $file.FullName
}

Export-ModuleMember -Function *
