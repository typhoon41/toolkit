function Test-ReleaseStateAsset {
    # Whether an asset name is one of the release-state assets (never a build artifact).
    param([Parameter(Mandatory)] [string] $Name)
    $names = Get-ReleaseStateName
    $Name -in $names.Marker, $names.Superseded -or $Name -match $names.AttemptPattern
}
