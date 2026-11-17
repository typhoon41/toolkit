function New-ReleasePlan {
    <#
        The release plan of this build: one entry per unit of release.json (see New-UnitReleasePlan).
        Run it from the repository root with tags fetched. Units with a problem are kept in the plan with
        their 'problem' set, so a caller can report every problem at once.
    #>
    param(
        [Parameter(Mandatory)] [string] $RepositoryRoot,
        [Parameter(Mandatory)] [string] $SourceBranch,
        [Parameter(Mandatory)] [ValidatePattern('^[0-9]+$')] [string] $BuildId,
        [string] $ReleaseBranch = 'refs/heads/main',
        [string] $PullRequestSourceBranch,
        [string] $PipelineVersion,
        [string] $ConfigurationPath = 'release.json'
    )
    $configuration = Read-ReleaseConfiguration -RepositoryRoot $RepositoryRoot -Path $ConfigurationPath
    $isReleaseBranch = $SourceBranch -eq $ReleaseBranch -and -not $PullRequestSourceBranch
    $words = Get-BranchLabel $(if ($PullRequestSourceBranch) { $PullRequestSourceBranch } else { $SourceBranch })
    $label = if ($isReleaseBranch -or -not $words) { 'ci' } else { $words }

    & git rev-parse --verify --quiet 'HEAD^' *> $null
    $hasParent = $LASTEXITCODE -eq 0
    $context = [pscustomobject]@{
        Current         = New-RepositorySnapshot -RepositoryRoot $RepositoryRoot
        Previous        = if ($hasParent) { New-RepositorySnapshot -RepositoryRoot $RepositoryRoot -Revision 'HEAD^' } else { $null }
        Commit          = [string](Invoke-Git rev-parse HEAD)
        IsReleaseBranch = $isReleaseBranch
        BuildId         = $BuildId
        Label           = $label
        PipelineVersion = $PipelineVersion
    }

    $units = @(foreach ($unit in $configuration.Units) {
        New-UnitReleasePlan -Unit $unit -Context $context
    })
    # The configured unit names the run; otherwise the first releasing unit, otherwise the first unit.
    $runNameUnit = @(
        @($units | Where-Object { $_.name -eq $configuration.RunNameUnit })
        @($units | Where-Object { $_.canRelease })
        $units[0]
    ) | Select-Object -First 1
    [pscustomobject]@{
        schemaVersion   = 1
        commit          = $context.Commit
        sourceBranch    = $SourceBranch
        releaseBranch   = $ReleaseBranch
        isReleaseBranch = $isReleaseBranch
        buildId         = $BuildId
        label           = $label
        runName         = Get-RunName -UnitPlan $runNameUnit -BuildId $BuildId -IsReleaseBranch $isReleaseBranch -Label $label
        hasRelease      = [bool](@($units | Where-Object { $_.canRelease }).Count)
        units           = $units
    }
}
