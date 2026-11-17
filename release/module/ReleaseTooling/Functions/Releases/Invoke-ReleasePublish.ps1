function Invoke-ReleasePublish {
    <#
        Re-checks the release order (no higher version may have been released while this run waited),
        verifies the assets, then publishes the draft. GitHub creates the tag at the commit at that moment.
    #>
    param([Parameter(Mandatory)] $Context, [AllowNull()] $Release)
    if (-not $Release) {
        throw "No draft release for $($Context.Tag); run the Prepare phase first."
    }
    if ($Release.target_commitish -ne $Context.Commit) {
        throw "Draft $($Context.Tag) targets $($Release.target_commitish), not $($Context.Commit)."
    }
    $releases = Get-GitHubRelease -Client $Context.Client
    Assert-ReleaseOrder -Context $Context -Releases $releases          # immediately before publication
    Assert-NoUnfinishedRelease -Context $Context -Releases $releases
    [void](Assert-TagTarget -Context $Context)
    Sync-ReleaseAsset -Context $Context -Release $Release -VerifyOnly -FrozenReason (Get-FrozenReason $Context)

    $published = Invoke-GitHubApi -Client $Context.Client -Method Patch -Path "releases/$($Release.id)" -Body @{
        draft       = $false
        make_latest = if ($Context.Candidate.IsPrerelease) { 'false' } else { 'true' }
    }
    $commit = Assert-TagTarget -Context $Context
    if (-not $commit) {
        throw "Release $($Context.Tag) was published but GitHub reports no tag; check the release manually."
    }
    Remove-ReleaseMarker -Context $Context -Release $published
    Write-ReleaseLog "Published $($Context.Tag) at $commit`: $($published.html_url)"
}
