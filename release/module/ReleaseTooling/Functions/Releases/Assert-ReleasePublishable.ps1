function Assert-ReleasePublishable {
    param([Parameter(Mandatory)] $Context)
    $releases = Get-GitHubRelease -Client $Context.Client
    Assert-ReleaseOrder -Context $Context -Releases $releases
    Assert-NoUnfinishedRelease -Context $Context -Releases $releases
    [void](Assert-TagTarget -Context $Context)
}
