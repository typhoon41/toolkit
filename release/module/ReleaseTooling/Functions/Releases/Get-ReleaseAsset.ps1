function Get-ReleaseAsset {
    param(
        [Parameter(Mandatory)] $Context,
        [AllowNull()] $Release,
        [string] $Name,
        [switch] $Attempts
    )
    if (-not $Release) {
        return
    }
    $assets = @(Get-GitHubCollection -Client $Context.Client -Path "releases/$($Release.id)/assets")
    if ($Name) {
        return @($assets | Where-Object { $_.name -eq $Name }) | Select-Object -First 1
    }
    if ($Attempts) {
        $pattern = (Get-ReleaseStateName).AttemptPattern
        return $assets | Where-Object { $_.name -match $pattern }      # callers collect with @()
    }
    $assets
}
