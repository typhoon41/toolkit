<#
.SYNOPSIS
    Requires the owning convention skills to be loaded before a source file is edited.

.DESCRIPTION
    One script for three hook events:
      PostToolUse (Skill)          records a loaded `conventions:<skill>`.
      UserPromptExpansion          records `/conventions:<skill>` run by the user.
      PreToolUse (Edit|Write|...)  blocks (exit 2) an edit of a file whose extension needs skills that are not
                                   loaded yet, naming the Skill calls to make; the edit is retried afterwards.
    Loaded skills are tracked per session and per subagent (Get-SkillMarkerPath). Required skills per extension
    live in RequiredSkills.psd1.
#>
[CmdletBinding()]
param(
    [string] $ConfigurationPath = (Join-Path $PSScriptRoot 'RequiredSkills.psd1'),
    [string] $MarkerRoot = (Join-Path ([IO.Path]::GetTempPath()) 'claude-conventions')
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'ConventionHooks') -Force

$payload = Read-HookPayload
$configuration = Import-PowerShellDataFile -LiteralPath $ConfigurationPath
$skillPattern = '^' + [regex]::Escape($configuration.Plugin) + ':([\w-]+)$'
$markerPath = Get-SkillMarkerPath -Payload $payload -MarkerRoot $MarkerRoot
$toolInput = if ($payload.PSObject.Properties['tool_input']) { $payload.tool_input } else { $null }

switch (Get-PayloadValue -Payload $payload -Name 'hook_event_name') {
    'PostToolUse' {
        if ((Get-PayloadValue -Payload $toolInput -Name 'skill') -match $skillPattern) {
            Add-LoadedSkill -MarkerPath $markerPath -Skill $Matches[1]
        }
        exit 0
    }
    'UserPromptExpansion' {
        if ((Get-PayloadValue -Payload $payload -Name 'command_name') -match $skillPattern) {
            Add-LoadedSkill -MarkerPath $markerPath -Skill $Matches[1]
        }
        exit 0
    }
}

$path = Get-PayloadValue -Payload $toolInput -Name 'file_path'
$extension = [IO.Path]::GetExtension($path).ToLowerInvariant()
if (-not $path -or -not $configuration.Extensions.ContainsKey($extension) -or -not (Test-GuardedPath -Path $path)) {
    exit 0
}
$missing = @(Get-MissingSkill -MarkerPath $markerPath -Required $configuration.Extensions[$extension])
if ($missing.Count -eq 0) {
    exit 0
}
$calls = ($missing | ForEach-Object { "Skill(skill: `"$($configuration.Plugin):$_`")" }) -join ', '
[Console]::Error.WriteLine(("Before editing $(Split-Path -Leaf $path), load the convention skills it needs: $calls. " +
    'Follow them, then retry the edit. Each session and subagent loads them once.'))
exit 2
