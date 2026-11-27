<#
.SYNOPSIS
    Writes an .npmrc naming registry.npmjs.org when the project commits none, so npmAuthenticate@0 has a file to
    authenticate. A committed .npmrc is used as it is.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Path
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force

if (Initialize-NpmUserConfiguration -Path $Path) {
    Write-ReleaseLog "No .npmrc at $($Path): wrote one naming the default npm registry."
}
else {
    Write-ReleaseLog "Using the committed $($Path)."
}
