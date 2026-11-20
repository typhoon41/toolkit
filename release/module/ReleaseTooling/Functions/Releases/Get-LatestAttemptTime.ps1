function Get-LatestAttemptTime {
    param([Parameter(Mandatory)] $Context, [Parameter(Mandatory)] $Release, [Parameter(Mandatory)] $Marker)
    $times = @(Get-ReleaseAsset -Context $Context -Release $Release -Attempts | ForEach-Object { ConvertTo-UtcTimestamp $_.created_at })
    if ($times.Count -eq 0) {
        return ConvertTo-UtcTimestamp $Marker.created_at
    }
    ($times | Sort-Object -Descending)[0]
}
