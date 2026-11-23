<#
.SYNOPSIS
    Writes the release notes of every releasing unit of a plan: <OutDirectory>/<unit>.md and <unit>.txt.

.DESCRIPTION
    In a pipeline: -PlanFile <plan.json> -OutDirectory <dir> -Repository owner/name, a read token in GITHUB_TOKEN.
    Locally: -Unit <name> -Version 1.4.0 -Preview. Public repositories need no token. In a release job,
    -UseCheckoutCredentials reads the GitHub service connection the toolkit checkout persisted instead.
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
    [switch] $Preview,
    [switch] $UseCheckoutCredentials
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force

Push-Location -LiteralPath $RepositoryRoot
try {
    if (-not $Repository) {
        $Repository = Get-GitHubRepositoryName
    }
    $client = New-GitHubClient -Repository $Repository -Token $env:GITHUB_TOKEN -ApiUrl $ApiUrl -WebUrl $WebUrl `
        -UseCheckoutCredentials:$UseCheckoutCredentials
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
