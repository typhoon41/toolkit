function Assert-ReleasePublishable {
    <#
        The checks that must hold at the moment a draft is published, read fresh from GitHub: no higher version
        was released, no older release is unfinished, and the tag doesn't point to another commit.
    #>
    param([Parameter(Mandatory)] $Context)
    $releases = Get-GitHubRelease -Client $Context.Client
    Assert-ReleaseOrder -Context $Context -Releases $releases
    Assert-NoUnfinishedRelease -Context $Context -Releases $releases
    [void](Assert-TagTarget -Context $Context)
}
