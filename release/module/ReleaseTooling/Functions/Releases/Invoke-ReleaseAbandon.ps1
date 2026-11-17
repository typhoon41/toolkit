function Invoke-ReleaseAbandon {
    <#
        Maintainer-only. Marks a started-but-unfinishable draft as SUPERSEDED so a higher version may be released.
        Allowed only when this build's packages are provably NOT what is on the feed: the feed holds a different
        package under the version, or nothing is there and the latest push attempt is older than
        -MinimumAgeMinutes (indexing lag has passed). The draft and its assets stay as a record.
    #>
    param([Parameter(Mandatory)] $Context, [AllowNull()] $Release, [int] $MinimumAgeMinutes = 60)
    if (-not $Release) {
        throw "No draft release for $($Context.Tag)."
    }
    if (Test-ReleaseSuperseded -Context $Context -Release $Release) {
        Write-ReleaseLog "Release $($Context.Tag) is already superseded."
        return
    }
    $names = Get-ReleaseStateName
    $marker = Get-ReleaseAsset -Context $Context -Release $Release -Name $names.Marker
    if (-not $marker) {
        throw "Draft $($Context.Tag) never started publication; nothing to abandon. Delete it on GitHub if you don't want it."
    }
    if ($Release.target_commitish -ne $Context.Commit) {
        throw "Draft $($Context.Tag) targets $($Release.target_commitish), not $($Context.Commit)."
    }
    $attemptCount = @(Get-ReleaseAsset -Context $Context -Release $Release -Attempts).Count
    Sync-ReleaseAsset -Context $Context -Release $Release -VerifyOnly -FrozenReason ("Abandon must be run with the draft's own " +
        "assets: download every asset of draft $($Context.Tag) (except the release-state files) into the unit's packages folder and retry.")

    $state = Get-UnitFeedState -UnitPlan $Context.Unit -Files $Context.Files -Commit $Context.Commit
    if ($state.Count -eq 0) {
        throw "No primary package among the draft's assets; nothing to evaluate."
    }
    $published = @($state | Where-Object State -eq 'Published' | ForEach-Object Label)
    $foreign = @($state | Where-Object State -eq 'Foreign' | ForEach-Object Label)
    Assert-AbandonAllowed -Context $Context -Release $Release -Marker $marker -Published $published -Foreign $foreign -MinimumAgeMinutes $MinimumAgeMinutes

    # Best-effort concurrency check; the docs require the release pipeline to be disabled meanwhile.
    if (@(Get-ReleaseAsset -Context $Context -Release $Release -Attempts).Count -ne $attemptCount) {
        throw "A pipeline run attempted to publish $($Context.Tag) while Abandon was evaluating. Disable the release pipeline and retry."
    }
    Add-ReleaseStateAsset -Context $Context -Release $Release -Name $names.Superseded -Content @{      # BEFORE the marker goes
        version = $Context.Candidate.Text; commit = $Context.Commit; state = 'superseded'; at = [DateTimeOffset]::UtcNow.ToString('o')
        publishedOnFeed = $published; foreignOnFeed = $foreign
    }
    Invoke-GitHubApi -Client $Context.Client -Method Delete -Path "releases/assets/$($marker.id)" | Out-Null
    $banner = '**SUPERSEDED by a maintainer. Do not publish this draft.**'
    if ($published.Count -gt 0) {
        $banner += "`n`nPublished on the feed without a GitHub release: $($published -join ', ')."
    }
    if ($foreign.Count -gt 0) {
        $banner += "`n`nVersion taken on the feed by a foreign package: $($foreign -join ', ')."
    }
    Invoke-GitHubApi -Client $Context.Client -Method Patch -Path "releases/$($Release.id)" -Body @{
        name = "$($Context.Tag) (superseded - do not publish)"; body = "$banner`n`n" + [string]$Release.body
    } | Out-Null
    Write-ReleaseLog "Release $($Context.Tag) is superseded. Higher versions may now be released; bump the version."
}
