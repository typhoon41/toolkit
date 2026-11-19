function Get-PayloadValue {
    # A string property of a hook payload object, or '' when the property is absent (safe under strict mode).
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
