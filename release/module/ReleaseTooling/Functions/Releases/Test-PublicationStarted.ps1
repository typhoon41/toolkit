function Test-PublicationStarted {
    # The feed is a second signal, in case the marker was removed by hand.
    param([Parameter(Mandatory)] $Context, [Parameter(Mandatory)] [string] $VersionText, [AllowNull()] $Release)
    if (Get-ReleaseAsset -Context $Context -Release $Release -Name (Get-ReleaseStateName).Marker) {
        return $true
    }
    foreach ($packageId in $Context.PackageIds) {
        if (Test-FeedVersion -UnitPlan $Context.Unit -Id $packageId -Version $VersionText) {
            return $true
        }
    }
    $false
}
