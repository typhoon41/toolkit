<#
.SYNOPSIS
    Writes ESLint-style release notes for every releasing unit of a plan: <OutDirectory>/<unit>.md (GitHub
    release body) and <unit>.txt (plain text for package release notes).

.DESCRIPTION
    Notes cover the commits since the unit's previous release tag that touch the unit's paths, grouped
    into Breaking Changes, Features, Bug Fixes, Documentation and Chores. A merged PR contributes its
    Conventional Commits, or its title when it has none; anything not following the convention is a chore.

    In a pipeline:  -PlanFile <plan.json> -OutDirectory <dir> -Repository owner/name, token in GITHUB_TOKEN
    Locally:        -Unit <name> -Version 1.4.0 -Preview     (repository taken from the origin remote)

    The token only needs read access to pull requests and contents; public repositories work without one.
#>
[CmdletBinding(DefaultParameterSetName = 'Plan')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Plan')] [string] $PlanFile,
    [Parameter(Mandatory, ParameterSetName = 'Preview')] [string] $Version,
    [Parameter(ParameterSetName = 'Plan')] [Parameter(Mandatory, ParameterSetName = 'Preview')] [string] $Unit,
    [string] $OutDirectory,
    [string] $Repository,
    [string] $RepositoryRoot = '.',
    [string] $ApiUrl = 'https://api.github.com',
    [string] $WebUrl = 'https://github.com',
    [switch] $SkipPullRequests,
    [switch] $Preview
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force

Push-Location -LiteralPath $RepositoryRoot
try {
    if (-not $Repository) {
        $Repository = Get-GitHubRepositoryName
    }
    $client = New-GitHubClient -Repository $Repository -Token $env:GITHUB_TOKEN -ApiUrl $ApiUrl -WebUrl $WebUrl
    $units = if ($PSCmdlet.ParameterSetName -eq 'Preview') {
        @(New-PreviewUnitPlan -RepositoryRoot '.' -UnitName $Unit -Version $Version)
    }
    else {
        $plan = Get-Content -LiteralPath $PlanFile -Raw | ConvertFrom-Json
        @($plan.units | Where-Object { $_.canRelease -and (-not $Unit -or $_.name -eq $Unit) })
    }
    if ($units.Count -eq 0) {
        Write-ReleaseLog 'No unit releases in this build; no release notes written.'
        exit 0
    }
    if (-not $OutDirectory -and -not $Preview) {
        throw 'Pass -OutDirectory, or -Preview to only print the notes.'
    }

    foreach ($unitPlan in $units) {
        $notes = New-UnitReleaseNote -UnitPlan $unitPlan -Client $client -SkipPullRequests:$SkipPullRequests
        Write-ReleaseLog "Release notes for $($unitPlan.tag): $($notes.EntryCount) entries from $($notes.Range)"
        if ($OutDirectory) {
            New-Item -ItemType Directory -Force -Path $OutDirectory | Out-Null
            $encoding = [Text.UTF8Encoding]::new($false)
            [IO.File]::WriteAllText((Join-Path (Resolve-Path $OutDirectory) "$($unitPlan.name).md"), $notes.Markdown, $encoding)
            [IO.File]::WriteAllText((Join-Path (Resolve-Path $OutDirectory) "$($unitPlan.name).txt"), $notes.Text, $encoding)
        }
        foreach ($line in $notes.Markdown -split '\r?\n') {
            Write-ReleaseLog "  $line"      # neutralises logging commands hidden in commit messages
        }
    }
}
catch {
    Write-PipelineIssue -Type error -Message $_.Exception.Message
    exit 1
}
finally {
    Pop-Location
}
