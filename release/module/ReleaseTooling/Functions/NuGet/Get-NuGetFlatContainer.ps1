function Get-NuGetFlatContainer {
    param([Parameter(Mandatory)] [string] $Source, [hashtable] $Headers = @{})
    $index = Invoke-RestMethod -Uri $Source -Headers $Headers
    $resource = @($index.resources | Where-Object { $_.'@type' -like 'PackageBaseAddress/3.0.0*' }) | Select-Object -First 1
    if (-not $resource) {
        throw "The feed $Source has no PackageBaseAddress resource."
    }
    $resource.'@id'.TrimEnd('/') + '/'
}
