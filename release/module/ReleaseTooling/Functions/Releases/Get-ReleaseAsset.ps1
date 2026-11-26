function Get-ReleaseAsset {
    param(
        [Parameter(Mandatory)] $Context,
        [AllowNull()] $Release,
        [switch] $Marker,
        [switch] $Superseded,
        [switch] $Attempts
    )
    if (-not $Release) {
        return
    }
    $assets = @(Get-GitHubCollection -Client $Context.Client -Path "releases/$($Release.id)/assets")
    if ($Marker -or $Superseded) {
        $name = if ($Marker) { [ReleaseStateName]::Marker } else { [ReleaseStateName]::Superseded }
        return @($assets | Where-Object { $_.name -eq $name }) | Select-Object -First 1
    }
    if ($Attempts) {
        return $assets | Where-Object { $_.name -match [ReleaseStateName]::AttemptPattern }      # callers collect with @()
    }
    $assets
}
