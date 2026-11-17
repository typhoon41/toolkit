<#
.SYNOPSIS
    Decides the version of every release unit in release.json, whether this build releases it, and the
    name of the run. Writes the plan to -OutFile for every later step.

.DESCRIPTION
    NuGet units: <Version> from the csproj, otherwise from the nearest Directory.Build.props.
    npm units:   "version" from package.json.
    Pipeline units (applications): -PipelineVersion, e.g. $(Build.BuildNumber).

    A package unit releases only on the release branch, on the commit that changes its version, when that
    version is not tagged yet and higher than every release. Other builds pack a CI version:
    1.3.1-ci.4711 on the release branch, 1.3.1-<branch words>.4711 elsewhere.

    Output variables (reference as $(<stepName>.<name>)):
      HasRelease   'true' when at least one unit releases
      RunName      the run name this step also applied
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
