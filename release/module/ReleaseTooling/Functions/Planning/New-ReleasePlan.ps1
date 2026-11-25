function New-ReleasePlan {
    # Run from the repository root with tags fetched. A unit with a problem stays in the plan, so a caller can report
    # every problem at once.
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
    $runNameUnit = @(
        @($units | Where-Object { $_.name -eq $configuration.RunNameUnit })
        @($units | Where-Object { $_.canRelease })
        $units[0]
    ) | Select-Object -First 1
    $runName = Get-RunName -UnitPlan $runNameUnit -IsReleaseBranch $isReleaseBranch -Label $label
    [pscustomobject]@{
        schemaVersion   = 1
        commit          = $context.Commit
        sourceBranch    = $SourceBranch
        releaseBranch   = $ReleaseBranch
        isReleaseBranch = $isReleaseBranch
        buildId         = $BuildId
        label           = $label
        runName         = $runName.Text
        runNameCounted  = $runName.CountsRuns
        hasRelease      = [bool](@($units | Where-Object { $_.canRelease }).Count)
        units           = $units
    }
}
