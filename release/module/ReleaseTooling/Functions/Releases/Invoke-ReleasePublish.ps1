function Invoke-ReleasePublish {
    <#
        Publishes the draft, which makes GitHub create the tag at the commit. Only after Prepare completed
        (the marker is on the draft) and every package is on its feed as this build's exact package; the
        release order is re-checked (no higher version may have been released while this run waited).
    #>
    param([Parameter(Mandatory)] $Context, [AllowNull()] $Release, [int] $FeedWaitMinutes = 15)
    if (-not $Release) {
        throw "No draft release for $($Context.Tag); run the Prepare phase first."
    }
    if ($Release.target_commitish -ne $Context.Commit) {
        throw "Draft $($Context.Tag) targets $($Release.target_commitish), not $($Context.Commit)."
    }
    if (-not (Get-ReleaseAsset -Context $Context -Release $Release -Name (Get-ReleaseStateName).Marker)) {
        throw "Prepare did not complete for $($Context.Tag); run Prepare, then the feed push, then Publish."
    }
    Assert-ReleasePublishable -Context $Context                        # fail fast, before any waiting
    Sync-ReleaseAsset -Context $Context -Release $Release -VerifyOnly -FrozenReason (Get-FrozenReason $Context)
    Wait-UnitFeedPublication -Context $Context -TimeoutMinutes $FeedWaitMinutes
    Assert-ReleasePublishable -Context $Context                        # again: the wait can take minutes

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
