function Get-PreviousReleaseTag {
    <#
        Baseline for release notes: the highest release tag reachable from -Ref that is lower than
        -Version. A stable release compares to the previous stable release; a prerelease to the
        previous release of any kind. Returns $null for a first release.
    #>
    param(
        [Parameter(Mandatory)] [string] $Prefix,
        [Parameter(Mandatory)] $Version,
        [string] $Ref = 'HEAD'
    )
    $eligible = @(Get-ReleaseTag -Prefix $Prefix -MergedInto $Ref | Where-Object {
        (Compare-ReleaseVersion $_.Version $Version) -lt 0 -and ($Version.IsPrerelease -or -not $_.Version.IsPrerelease)
    })
    Get-HighestRelease $eligible
}
