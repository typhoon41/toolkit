<#
.SYNOPSIS
    PostToolUse hook: reports banned patterns (BannedPatterns.psd1) in the text an Edit / Write / MultiEdit just wrote.

.DESCRIPTION
    Only the new text is checked, so code already in the file is never reported. Findings go to stderr with exit 2
    (the edit stays applied); otherwise it exits 0.
#>
[CmdletBinding()]
param(
    [string] $RulePath = (Join-Path $PSScriptRoot 'BannedPatterns.psd1')
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'ConventionHooks') -Force

$payload = Read-HookPayload
$toolInput = $payload.tool_input
$path = [string]$toolInput.file_path
if (-not $path -or -not (Test-GuardedPath -Path $path)) {
    exit 0
}

# PostToolUse runs after the write, so the file on disk is the result; an Edit's new text alone may lack context.
$fileContent = if (Test-Path -LiteralPath $path -PathType Leaf) { [string](Get-Content -LiteralPath $path -Raw) } else { '' }
$rules = @(Read-BannedPatternRule -Path $RulePath)
$projectPackages = @($rules.WhenProjectDependsOn | Where-Object { $_ } | Select-Object -Unique |
    Where-Object { Test-ProjectDependency -Path $path -Requirement (ConvertTo-DependencyRequirement -Text $_) })
$hits = @(Find-BannedPattern -Path $path -Text (Get-WrittenText -ToolInput $toolInput) -Rule $rules -FileContent $fileContent -ProjectPackage $projectPackages)
if ($hits.Count -eq 0) {
    exit 0
}
[Console]::Error.WriteLine((Format-GuardReport -Path $path -Hit $hits))
exit 2
