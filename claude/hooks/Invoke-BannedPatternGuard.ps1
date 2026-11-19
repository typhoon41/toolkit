<#
.SYNOPSIS
    PostToolUse hook: reports banned patterns in the text an Edit / Write / MultiEdit just wrote.

.DESCRIPTION
    Reads the hook payload (JSON) from stdin. Only the new text is checked, so code that was already in the file is
    never reported. On findings it writes them to stderr and exits 2: the edit is already applied, Claude receives
    the report as feedback. Without findings it exits 0 silently. Rules live in BannedPatterns.psd1.
#>
[CmdletBinding()]
param(
    [string] $RulePath = (Join-Path $PSScriptRoot 'BannedPatterns.psd1')
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'BannedPatternGuard') -Force

[Console]::InputEncoding = [Text.UTF8Encoding]::new($false)
$payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
$toolInput = $payload.tool_input
$path = [string]$toolInput.file_path
if (-not $path -or -not (Test-GuardedPath -Path $path)) {
    exit 0
}

$hits = @(Find-BannedPattern -Path $path -Text (Get-WrittenText -ToolInput $toolInput) -Rule (Read-BannedPatternRule -Path $RulePath))
if ($hits.Count -eq 0) {
    exit 0
}
[Console]::Error.WriteLine((Format-GuardReport -Path $path -Hit $hits))
exit 2
