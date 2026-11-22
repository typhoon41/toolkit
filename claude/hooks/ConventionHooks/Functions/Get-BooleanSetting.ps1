function Get-BooleanSetting {
    # A JSON true / false. An absent or null setting keeps the default; one of any other type ("false", 0, [], {})
    # keeps it too, with a warning on stderr, so a typo never switches a strict hook off. The property is read
    # directly: Get-JsonProperty would unroll an empty array into nothing and hide it.
    param(
        [Parameter(Mandatory)] [AllowNull()] [object] $Object,
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [bool] $Default,
        [string] $Source = '.claude/conventions.json'
    )
    $property = if ($Object -is [pscustomobject]) { $Object.PSObject.Properties[$Name] } else { $null }
    if (-not $property -or $null -eq $property.Value) {
        return $Default
    }
    if ($property.Value -is [bool]) {
        return $property.Value
    }
    [Console]::Error.WriteLine("Ignoring $Name in ${Source}: expected true or false.")
    $Default
}
