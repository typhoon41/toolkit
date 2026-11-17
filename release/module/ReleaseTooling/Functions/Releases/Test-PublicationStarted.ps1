function Test-PublicationStarted {
    <#
        Marker on the draft = Prepare finished and the feed push followed (the source of truth). The feed is a
        second signal, in case the marker was removed by hand.
    #>
    param([Parameter(Mandatory)] $Context, [Parameter(Mandatory)] [string] $VersionText, [AllowNull()] $Release)
    if (Get-ReleaseAsset -Context $Context -Release $Release -Name (Get-ReleaseStateName).Marker) {
        return $true
    }
    foreach ($id in $Context.PackageIds) {
        if (Test-FeedVersion -UnitPlan $Context.Unit -Id $id -Version $VersionText) {
            return $true
        }
    }
    $false
}
