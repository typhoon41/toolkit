function Remove-ReleaseMarker {
    param([Parameter(Mandatory)] $Context, [Parameter(Mandatory)] $Release)
    $marker = Get-ReleaseAsset -Context $Context -Release $Release -Name (Get-ReleaseStateName).Marker
    $toDelete = @(Get-ReleaseAsset -Context $Context -Release $Release -Attempts) + @($marker | Where-Object { $_ })
    foreach ($asset in $toDelete) {
        Invoke-GitHubApi -Client $Context.Client -Method Delete -Path "releases/assets/$($asset.id)" | Out-Null
    }
}
