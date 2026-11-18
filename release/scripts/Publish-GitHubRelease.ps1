<#
.SYNOPSIS
    Creates the GitHub release of every releasing unit of a plan, in resumable phases. Every phase can be
    re-run after any failure, including a lost API response.

.DESCRIPTION
    Package units (nuget, npm), around the feed push:
      -Action Prepare   create or resume a DRAFT release for the unit's tag at the plan's commit, set its notes
                        (<NotesDirectory>/<unit>.md, or a minimal body without notes) and make its assets match
                        the unit's packages exactly; then mark it as publishing (frozen). Run before the push.
      -Action Publish   once the marker is on the draft and every package is on its feed (waiting up to
                        -FeedWaitMinutes for indexing), re-check ordering and publish the draft (creates the tag).
      -Action Abandon   maintainer-only: mark a started-but-unfinishable draft as superseded (-Unit required).
      -Action Restore   maintainer-only: recreate a missing draft when the feed already holds this build's
                        packages (-Unit required; needs the complete original artifacts).
    Application units (pipeline): Publish creates and publishes the release and tag at once; the other actions
    skip them.

    Token: GITHUB_TOKEN environment variable (Contents: write). See docs/RELEASING.md for every refusal.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [ValidateSet('Prepare', 'Publish', 'Abandon', 'Restore')] [string] $Action,
    [Parameter(Mandatory)] [string] $PlanFile,
    [string] $PackagesPath = '',
    [string] $NotesDirectory = '',
    [string] $Unit,
    [string] $Repository,
    [int] $MinimumAgeMinutes = 60,
    [int] $FeedWaitMinutes = 15,
    [string] $ApiUrl = 'https://api.github.com',
    [string] $WebUrl = 'https://github.com'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force

try {
    if ($Action -in 'Abandon', 'Restore' -and -not $Unit) {
        throw "-Action $Action needs -Unit: it acts on one release only."
    }
    $plan = Get-Content -LiteralPath $PlanFile -Raw | ConvertFrom-Json
    if (-not $Repository) {
        $Repository = Get-GitHubRepositoryName
    }
    $client = New-GitHubClient -Repository $Repository -Token $env:GITHUB_TOKEN -ApiUrl $ApiUrl -WebUrl $WebUrl
    if (-not $client.HasToken) {
        throw 'GITHUB_TOKEN is not set.'
    }
    $units = @($plan.units | Where-Object { $_.canRelease -and (-not $Unit -or $_.name -eq $Unit) })
    if ($Unit -and $units.Count -eq 0) {
        $units = @($plan.units | Where-Object { $_.name -eq $Unit -and $Action -in 'Abandon', 'Restore' })
    }
    if ($units.Count -eq 0) {
        Write-ReleaseLog 'No unit releases in this build.'
        exit 0
    }

    foreach ($unitPlan in $units) {
        $notesFile = if ($NotesDirectory) { Join-Path $NotesDirectory "$($unitPlan.name).md" } else { '' }
        if ($unitPlan.type -eq 'pipeline') {
            if ($Action -eq 'Publish') {
                Publish-ApplicationRelease -Context (New-GitHubReleaseContext -Client $client -UnitPlan $unitPlan -Commit $plan.commit) -NotesFile $notesFile
            }
            else {
                Write-ReleaseLog "$($unitPlan.name) is an application unit; -Action $Action does not apply."
            }
            continue
        }
        $npmConfiguration = if ($unitPlan.type -eq 'npm') { Enable-NpmTokenAuthentication -Registry $unitPlan.npmRegistry } else { $null }
        try {
            Invoke-UnitGitHubRelease -Action $Action -Client $client -UnitPlan $unitPlan -Commit $plan.commit `
                -PackagesPath $PackagesPath -NotesFile $notesFile -MinimumAgeMinutes $MinimumAgeMinutes -FeedWaitMinutes $FeedWaitMinutes
        }
        finally {
            Disable-NpmTokenAuthentication $npmConfiguration
        }
    }
}
catch {
    Write-PipelineIssue -Type error -Message $_.Exception.Message
    exit 1
}
