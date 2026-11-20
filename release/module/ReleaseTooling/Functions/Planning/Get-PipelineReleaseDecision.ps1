function Get-PipelineReleaseDecision {
    # Re-running the build of an already tagged commit is allowed: the release step verifies instead of creating.
    param(
        [Parameter(Mandatory)] $Candidate,
        [AllowNull()] [AllowEmptyCollection()] [object[]] $Releases,
        [Parameter(Mandatory)] [bool] $IsReleaseBranch,
        [AllowNull()] [AllowEmptyString()] [string] $TaggedCommit,
        [Parameter(Mandatory)] [string] $HeadCommit
    )
    $same = @(@($Releases) | Where-Object { $_ -and $_.Version.Text -eq $Candidate.Text })
    $alreadyReleased = $same.Count -gt 0
    $highest = Get-HighestRelease @(@($Releases) | Where-Object { $_ -and $_.Version.Text -ne $Candidate.Text })

    $problem = $null
    if ($IsReleaseBranch -and $alreadyReleased -and $TaggedCommit -ne $HeadCommit) {
        $problem = "Version $($Candidate.Text) was already released as $($same[0].Tag) from another commit. The pipeline's version must be unique (e.g. name: X.Y.`$(Rev:r))."
    }
    elseif ($IsReleaseBranch -and -not $alreadyReleased -and $highest -and (Compare-ReleaseVersion $Candidate $highest.Version) -le 0) {
        $problem = "Version $($Candidate.Text) must be higher than the latest release $($highest.Tag). Raise the version in the pipeline."
    }

    [pscustomobject]@{
        CanRelease      = $IsReleaseBranch -and -not $problem
        AlreadyReleased = $alreadyReleased
        Highest         = $highest
        Problem         = $problem
        Warning         = $null
    }
}
