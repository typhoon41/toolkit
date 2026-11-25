<#
.SYNOPSIS
    Decides each release unit's version and whether this build releases it, names the run and writes -OutFile.

.DESCRIPTION
    A package unit releases only from the release-branch commit that changes its version.
    Output variables: HasRelease ('true' when a unit releases), RunName and RunNameCounted ('true' when
    jobs/run-counter.yml appends the per-version run counter).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $SourceBranch,
    [Parameter(Mandatory)] [ValidatePattern('^[0-9]+$')] [string] $BuildId,
    [Parameter(Mandatory)] [string] $OutFile,
    [string] $RepositoryRoot = '.',
    [string] $ReleaseBranch = 'refs/heads/main',
    [AllowEmptyString()] [string] $PullRequestSourceBranch = '',
    [AllowEmptyString()] [string] $PipelineVersion = '',
    [string] $ConfigurationPath = 'release.json',
    [switch] $KeepRunName
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force

# An unresolved Azure macro such as "$(System.PullRequest.SourceBranch)" outside a PR build means "not set".
if ($PullRequestSourceBranch -match '^\$\(') {
    $PullRequestSourceBranch = ''
}

Push-Location -LiteralPath $RepositoryRoot
try {
    $plan = New-ReleasePlan -RepositoryRoot '.' -SourceBranch $SourceBranch -BuildId $BuildId -ReleaseBranch $ReleaseBranch `
        -PullRequestSourceBranch $PullRequestSourceBranch -PipelineVersion $PipelineVersion -ConfigurationPath $ConfigurationPath

    foreach ($unit in $plan.units) {
        $release = if ($unit.canRelease) { "releases $($unit.tag)" } else { 'no release' }
        $latest = if ($unit.latestTag) { $unit.latestTag } else { '(none)' }
        Write-ReleaseLog ("{0,-28} {1,-9} version {2,-16} packs {3,-34} latest {4,-20} {5}" -f
            $unit.name, $unit.type, $unit.version, $unit.packageVersion, $latest, $release)
        if ($unit.warning) {
            Write-PipelineIssue -Type warning -Message "$($unit.name): $($unit.warning)"
        }
    }
    $problems = @($plan.units | Where-Object { $_.problem })
    foreach ($unit in $problems) {
        Write-PipelineIssue -Type error -Message "$($unit.name): $($unit.problem)"
    }
    if ($problems.Count -gt 0) {
        exit 1
    }

    $directory = Split-Path -Parent ([IO.Path]::GetFullPath($OutFile, (Get-Location).Path))
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    [IO.File]::WriteAllText([IO.Path]::GetFullPath($OutFile, (Get-Location).Path), ($plan | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
    Write-ReleaseLog "Plan written to $OutFile. Run name: $($plan.runName)"

    Set-PipelineVariable -Name HasRelease -Value $plan.hasRelease.ToString().ToLowerInvariant() -Output
    Set-PipelineVariable -Name RunName -Value $plan.runName -Output
    Set-PipelineVariable -Name RunNameCounted -Value $plan.runNameCounted.ToString().ToLowerInvariant() -Output
    if (-not $KeepRunName) {
        Set-PipelineBuildNumber -BuildNumber $plan.runName
    }
}
catch {
    Write-PipelineIssue -Type error -Message $_.Exception.Message
    exit 1
}
finally {
    Pop-Location
}
