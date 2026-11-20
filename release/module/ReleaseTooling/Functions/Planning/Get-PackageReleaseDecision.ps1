function Get-PackageReleaseDecision {
    # Only the release-branch commit that changes the version releases it. A Problem fails the build.
    param(
        [Parameter(Mandatory)] $Candidate,
        [AllowNull()] [AllowEmptyString()] [string] $PreviousText,
        [AllowNull()] [AllowEmptyCollection()] [object[]] $Releases,
        [Parameter(Mandatory)] [bool] $IsReleaseBranch,
        [Parameter(Mandatory)] [string] $VersionSource
    )
    $versionChanged = $PreviousText -ne $Candidate.Text
    $same = @(@($Releases) | Where-Object { $_ -and $_.Version.Text -eq $Candidate.Text })
    $alreadyReleased = $same.Count -gt 0
    $highest = Get-HighestRelease @(@($Releases) | Where-Object { $_ -and $_.Version.Text -ne $Candidate.Text })

    $problem = $null
    if ($alreadyReleased -and $versionChanged) {
        $problem = "Version $($Candidate.Text) was already released as $($same[0].Tag). Choose a version higher than every release in $VersionSource."
    }
    elseif (-not $alreadyReleased -and $highest -and (Compare-ReleaseVersion $Candidate $highest.Version) -le 0) {
        $problem = "Version $($Candidate.Text) must be higher than the latest release $($highest.Tag) (prereleases count too). Bump <Version>/version in $VersionSource."
    }

    $warning = $null
    if ($IsReleaseBranch -and -not $versionChanged -and -not $alreadyReleased -and -not $problem) {
        $warning = "Version $($Candidate.Text) is not released, but this commit didn't change it, so it won't be released from here. " +
                   'Re-run the pipeline for the commit that bumped the version, or bump it again.'
    }

    [pscustomobject]@{
        CanRelease      = $IsReleaseBranch -and $versionChanged -and -not $alreadyReleased -and -not $problem
        AlreadyReleased = $alreadyReleased
        Highest         = $highest
        Problem         = $problem
        Warning         = $warning
    }
}
