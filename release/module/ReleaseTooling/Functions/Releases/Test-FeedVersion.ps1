function Test-FeedVersion {
    # Whether package -Id (NuGet id or npm name) exists in -Version on the unit's feed.
    param([Parameter(Mandatory)] $UnitPlan, [Parameter(Mandatory)] [string] $Id, [Parameter(Mandatory)] [string] $Version)
    if ($UnitPlan.type -eq 'npm') {
        return [bool](Get-NpmPublishedIntegrity -Name $Id -Version $Version -Registry $UnitPlan.npmRegistry)
    }
    $headers = Get-NuGetFeedHeader -Source $UnitPlan.nugetSource
    $flatContainer = Get-NuGetFlatContainer -Source $UnitPlan.nugetSource -Headers $headers
    Test-NuGetVersion -FlatContainer $flatContainer -Id $Id -Version $Version -Headers $headers
}
