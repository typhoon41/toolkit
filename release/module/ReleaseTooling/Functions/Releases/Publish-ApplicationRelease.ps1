function Publish-ApplicationRelease {
    # No assets, so no draft phase. The order check cannot be raced: the deployment job holds an Exclusive
    # environment lock (release-application.yml).
    param([Parameter(Mandatory)] $Context, [string] $NotesFile)
    $releases = Get-GitHubRelease -Client $Context.Client
    $release = Find-UnitRelease -Context $Context -Releases $releases
    if ($release -and -not $release.draft) {
        [void](Assert-TagTarget -Context $Context -MissingReason "Release $($Context.Tag) is published but its tag is missing.")
        Write-ReleaseLog "Release $($Context.Tag) is already published and verified: $($release.html_url)"
        return
    }
    Assert-ReleasePublishable -Context $Context       # fresh: no higher version was released before this run got the lock
    $payload = New-ReleasePayload -Context $Context -NotesFile $NotesFile -Draft $false
    $published = if ($release) {
        Invoke-GitHubApi -Client $Context.Client -Method Patch -Path "releases/$($release.id)" -Body $payload
    }
    else {
        Invoke-GitHubApi -Client $Context.Client -Method Post -Path 'releases' -Body $payload
    }
    $commit = Assert-TagTarget -Context $Context -MissingReason "Release $($Context.Tag) was published but GitHub reports no tag; check the release manually."
    Write-ReleaseLog "Published $($Context.Tag) at $commit`: $($published.html_url)"
}
