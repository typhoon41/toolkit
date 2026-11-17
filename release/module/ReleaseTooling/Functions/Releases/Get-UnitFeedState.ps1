function Get-UnitFeedState {
    # Feed state (Absent / Published / Foreign) of every primary package of a unit: .nupkg or .tgz, not symbols.
    param(
        [Parameter(Mandatory)] $UnitPlan,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [IO.FileInfo[]] $Files,
        [Parameter(Mandatory)] [string] $Commit
    )
    $states = @(foreach ($file in @($Files | Where-Object { $_.Extension -in '.nupkg', '.tgz' })) {
        if ($UnitPlan.type -eq 'nuget') {
            Get-NuGetPackageState -File $file.FullName -Source $UnitPlan.nugetSource -Commit $Commit
        }
        else {
            Get-NpmPackageState -File $file.FullName -Registry $UnitPlan.npmRegistry
        }
    })
    foreach ($state in $states) {
        Write-ReleaseLog ("{0,-9}: {1} {2}" -f $state.State, $state.Label, $state.Detail)
    }
    , $states
}
