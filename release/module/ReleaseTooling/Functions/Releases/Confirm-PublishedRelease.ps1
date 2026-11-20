function Confirm-PublishedRelease {
    param([Parameter(Mandatory)] $Context, [Parameter(Mandatory)] $Release)
    $commit = Assert-TagTarget -Context $Context
    if (-not $commit) {
        throw "Release $($Context.Tag) is published but its tag is missing."
    }
    Sync-ReleaseAsset -Context $Context -Release $Release -VerifyOnly -FrozenReason (Get-FrozenReason $Context)
    Remove-ReleaseMarker -Context $Context -Release $Release
    Write-ReleaseLog "Release $($Context.Tag) is already published and verified: $($Release.html_url)"
}
