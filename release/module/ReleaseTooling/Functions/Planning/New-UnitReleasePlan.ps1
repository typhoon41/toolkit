function New-UnitReleasePlan {
    param([Parameter(Mandatory)] $Unit, [Parameter(Mandatory)] $Context)
    if ($Unit.Type -eq 'pipeline') {
        $text = $Context.PipelineVersion
        $source = 'the pipeline (-PipelineVersion)'
        $sourceFiles = @()
        $packageNames = @()
        if (-not $text) {
            throw "Unit '$($Unit.Name)' takes its version from the pipeline; pass -PipelineVersion (e.g. `$(Build.BuildNumber))."
        }
    }
    else {
        $current = Read-UnitVersion -Unit $Unit -Snapshot $Context.Current
        if (-not $current) {
            throw "Unit '$($Unit.Name)': $(@($Unit.Projects) + @($Unit.Package) | Where-Object { $_ } | Select-Object -First 1) does not exist."
        }
        $text = $current.Text
        $source = $current.SourceFiles -join ', '
        $sourceFiles = $current.SourceFiles
        $packageNames = $current.PackageNames
    }

    $candidate = ConvertTo-ReleaseVersion $text
    if (-not $candidate) {
        throw "Unit '$($Unit.Name)': version '$text' from $source is invalid: $(Get-VersionProblem $text)."
    }
    $releases = @(Get-ReleaseTag -Prefix $Unit.TagPrefix)
    $tag = "$($Unit.TagPrefix)$($candidate.Text)"

    if ($Unit.Type -eq 'pipeline') {
        $decision = Get-PipelineReleaseDecision -Candidate $candidate -Releases $releases -IsReleaseBranch $Context.IsReleaseBranch `
            -TaggedCommit (Get-TagTargetCommit $tag) -HeadCommit $Context.Commit
        $packageVersion = $candidate.Text
    }
    else {
        $previous = if ($Context.Previous) { try { Read-UnitVersion -Unit $Unit -Snapshot $Context.Previous } catch { $null } } else { $null }
        $decision = Get-PackageReleaseDecision -Candidate $candidate -PreviousText ($previous ? $previous.Text : $null) `
            -Releases $releases -IsReleaseBranch $Context.IsReleaseBranch -VersionSource $source
        $packageVersion = if ($decision.CanRelease) { $candidate.Text }
                          else { Get-ContinuousIntegrationVersion -Version $candidate -BuildId $Context.BuildId -Label $Context.Label -AlreadyReleased:$decision.AlreadyReleased }
    }
    $previousTag = Get-PreviousReleaseTag -Prefix $Unit.TagPrefix -Version $candidate

    [pscustomobject]@{
        name           = $Unit.Name
        type           = $Unit.Type
        version        = $candidate.Text
        packageVersion = $packageVersion
        isPrerelease   = $candidate.IsPrerelease
        canRelease     = [bool]$decision.CanRelease
        tagPrefix      = $Unit.TagPrefix
        tag            = $tag
        previousTag    = if ($previousTag) { $previousTag.Tag } else { '' }
        latestTag      = if ($decision.Highest) { $decision.Highest.Tag } else { '' }
        versionSource  = $source
        paths          = Get-UnitReleaseScope -Unit $Unit -VersionSourceFiles $sourceFiles
        projects       = @($Unit.Projects)
        package        = $Unit.Package
        packageNames   = @($packageNames)
        nugetSource    = $Unit.NuGetSource
        npmRegistry    = $Unit.NpmRegistry
        problem        = $decision.Problem
        warning        = $decision.Warning
    }
}
