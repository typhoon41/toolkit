<#
.SYNOPSIS
    Requires the owning convention skills to be loaded before a source file is edited.

.DESCRIPTION
    PostToolUse (Skill) and UserPromptExpansion record a loaded <plugin>:<skill>; PreToolUse blocks (exit 2) an edit
    until the skills RequiredSkills.psd1 and the project's .claude/conventions.json name for the file are loaded. The
    project can switch the gate off (hooks.skillGate).
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
$project = Read-ProjectConfiguration -Root (Get-PayloadValue -Payload $payload -Name 'cwd')
if (-not $project.SkillGate) {
    exit 0
}
$configuration = Import-PowerShellDataFile -LiteralPath $ConfigurationPath
$plugin = Get-PluginName
$skillPattern = '^' + [regex]::Escape($plugin) + ':([\w-]+)$'
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
if (-not $path -or -not (Test-GuardedPath -Path $path -ExcludedFolder $project.ExcludedFolders)) {
    exit 0
}
$required = @(Get-RequiredSkill -Path $path -Configuration $configuration -ProjectRequiredSkill $project.RequiredSkills)
if ($required.Count -eq 0) {
    exit 0
}
$missing = @(Get-MissingSkill -MarkerPath $markerPath -Required $required)
if ($missing.Count -eq 0) {
    exit 0
}
$calls = ($missing | ForEach-Object { "Skill(skill: `"${plugin}:$_`")" }) -join ', '
[Console]::Error.WriteLine(("Before editing $(Split-Path -Leaf $path), load the convention skills it needs: $calls. " +
    'Follow them, then retry the edit. Each session and subagent loads them once.'))
exit 2
