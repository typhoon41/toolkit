function Test-PublicationStarted {
    # The feed is a second signal, in case the marker was removed by hand.
    param([Parameter(Mandatory)] $Context, [Parameter(Mandatory)] [string] $VersionText, [AllowNull()] $Release)
    if (Get-ReleaseAsset -Context $Context -Release $Release -Name (Get-ReleaseStateName).Marker) {
        return $true
    }
    $unit = $Context.Unit
    foreach ($packageId in $Context.PackageIds) {
        if ($unit.type -eq 'npm') {
            $published = [bool](Get-NpmPublishedIntegrity -Name $packageId -Version $VersionText -Registry $unit.npmRegistry)
        }
        else {
            $headers = Get-NuGetFeedHeader -Source $unit.nugetSource
            $flatContainer = Get-NuGetFlatContainer -Source $unit.nugetSource -Headers $headers
            $published = Test-NuGetVersion -FlatContainer $flatContainer -Id $packageId -Version $VersionText -Headers $headers
        }
        if ($published) {
            return $true
        }
    }
    $false
}
