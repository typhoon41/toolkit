<#
.SYNOPSIS
    PostToolUse hook: formats an edited .cs file's whitespace with `dotnet format` to match the .editorconfig.

.DESCRIPTION
    When the file changed, Claude is told to re-read it, or its next Edit would be refused as "modified since read".
    Always exits 0: formatting never blocks.
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'ConventionHooks') -Force

$payload = Read-HookPayload
$toolInput = if ($payload.PSObject.Properties['tool_input']) { $payload.tool_input } else { $null }
$path = Get-PayloadValue -Payload $toolInput -Name 'file_path'
$root = Get-PayloadValue -Payload $payload -Name 'cwd'
if (-not $path -or -not $root -or [IO.Path]::GetExtension($path) -ne '.cs' -or -not (Test-GuardedPath -Path $path)) {
    exit 0
}
if (Invoke-WhitespaceFormat -Root $root -Path $path) {
    @{
        hookSpecificOutput = @{
            hookEventName     = 'PostToolUse'
            additionalContext = "dotnet format reformatted the whitespace of $path to match .editorconfig. Re-read it before editing it again."
        }
    } | ConvertTo-Json -Compress -Depth 3
}
exit 0
