function Confirm-PublishedRelease {
    param([Parameter(Mandatory)] $Context, [Parameter(Mandatory)] $Release)
    [void](Assert-TagTarget -Context $Context -MissingReason "Release $($Context.Tag) is published but its tag is missing.")
    Sync-ReleaseAsset -Context $Context -Release $Release -VerifyOnly -FrozenReason (Get-FrozenReason $Context)
    Remove-ReleaseMarker -Context $Context -Release $Release
    Write-ReleaseLog "Release $($Context.Tag) is already published and verified: $($Release.html_url)"
}
