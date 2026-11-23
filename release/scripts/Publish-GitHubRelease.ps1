<#
.SYNOPSIS
    Creates the GitHub release of every releasing unit of a plan in phases; each is safe to re-run after any failure.

.DESCRIPTION
    Package units: Prepare (a frozen draft with assets) before the feed push, Publish (creates the tag) after it.
    Abandon and Restore are maintainer-only and need -Unit. Application units: Publish creates release and tag at once.
    GITHUB_TOKEN needs Contents: write; with -UseCheckoutCredentials the GitHub service connection the toolkit checkout
    persisted (its resource's endpoint) is used instead. docs/RELEASING.md lists every refusal.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [ValidateSet('Prepare', 'Publish', 'Abandon', 'Restore')] [string] $Action,
    [Parameter(Mandatory)] [string] $PlanFile,
    [string] $PackagesPath = '',
    [string] $NotesDirectory = '',
    [string] $Unit,
    [AllowEmptyString()] [string] $TrustedFeedHost = '',     # extra npm hosts that may receive NPM_TOKEN
    [string] $Repository,
    [int] $MinimumAgeMinutes = 60,
    [int] $FeedWaitMinutes = 15,
    [string] $ApiUrl = 'https://api.github.com',
    [string] $WebUrl = 'https://github.com',
    [switch] $UseCheckoutCredentials
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
    $client = New-GitHubClient -Repository $Repository -Token $env:GITHUB_TOKEN -ApiUrl $ApiUrl -WebUrl $WebUrl `
        -UseCheckoutCredentials:$UseCheckoutCredentials
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
        $npmConfiguration = if ($unitPlan.type -eq 'npm') { Enable-NpmTokenAuthentication -Registry $unitPlan.npmRegistry -TrustedHost (ConvertTo-TrustedFeedHost $TrustedFeedHost) } else { $null }
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
