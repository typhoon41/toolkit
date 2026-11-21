function Test-ReleaseStateAsset {
    param([Parameter(Mandatory)] [string] $Name)
    $names = Get-ReleaseStateName
    $Name -in $names.Marker, $names.Superseded -or $Name -match $names.AttemptPattern
}
