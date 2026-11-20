function Get-PayloadValue {
    # Safe under strict mode: an absent property gives ''.
    param(
        [Parameter(Mandatory)] [AllowNull()] [object] $Payload,
        [Parameter(Mandatory)] [string] $Name
    )
    if ($null -eq $Payload) {
        return ''
    }
    $property = $Payload.PSObject.Properties[$Name]
    if ($property -and $null -ne $property.Value) {
        return [string]$property.Value
    }
    ''
}
