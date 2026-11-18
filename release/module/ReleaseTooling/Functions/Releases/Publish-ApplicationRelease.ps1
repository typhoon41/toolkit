function Publish-ApplicationRelease {
    <#
        GitHub release + tag for an application (pipeline) unit, after its deployment. There are no assets, so
        no draft phase is needed: an existing published release is verified, a leftover draft is published,
        otherwise the release is created and published at once. Safe to re-run.
        Runs inside a deployment job whose environment has an Exclusive lock, so the order check below, read fresh
        right before publishing, can't be raced by another production run (release-application.yml).
    #>
    param([Parameter(Mandatory)] $Context, [string] $NotesFile)
    $releases = Get-GitHubRelease -Client $Context.Client
    $release = Find-UnitRelease -Context $Context -Releases $releases
    if ($release -and -not $release.draft) {
        $commit = Assert-TagTarget -Context $Context
        if (-not $commit) {
            throw "Release $($Context.Tag) is published but its tag is missing."
        }
        Write-ReleaseLog "Release $($Context.Tag) is already published and verified: $($release.html_url)"
        return
    }
    Assert-ReleasePublishable -Context $Context       # fresh: no higher version was released before this run got the lock
    $payload = New-ReleasePayload -Context $Context -Body (Get-ReleaseBody -Context $Context -NotesFile $NotesFile) -Draft $false
    $payload.make_latest = if ($Context.Candidate.IsPrerelease) { 'false' } else { 'true' }
    $published = if ($release) {
        Invoke-GitHubApi -Client $Context.Client -Method Patch -Path "releases/$($release.id)" -Body $payload
    }
    else {
        Invoke-GitHubApi -Client $Context.Client -Method Post -Path 'releases' -Body $payload
    }
    $commit = Assert-TagTarget -Context $Context
    if (-not $commit) {
        throw "Release $($Context.Tag) was published but GitHub reports no tag; check the release manually."
    }
    Write-ReleaseLog "Published $($Context.Tag) at $commit`: $($published.html_url)"
}
