function Get-JsonProperty {
    # Safe under strict mode: an absent or null property gives the default. PowerShell matches the name ignoring case.
    param(
        [Parameter(Mandatory)] [AllowNull()] [object] $Object,
        [Parameter(Mandatory)] [string] $Name,
        [AllowNull()] [object] $Default = $null
    )
    if ($null -eq $Object -or $Object -isnot [pscustomobject]) {
        return $Default
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($property -and $null -ne $property.Value) {
        return $property.Value
    }
    $Default
}
