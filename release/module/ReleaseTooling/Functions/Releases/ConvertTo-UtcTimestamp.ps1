function ConvertTo-UtcTimestamp {
    <#
        GitHub timestamps arrive as [DateTime] (Kind=Utc) from JSON, or as strings. Never go through string
        conversion: Parse() on a stringified DateTime would assume local time.
    #>
    param([Parameter(Mandatory)] $Value)
    if ($Value -is [DateTimeOffset]) {
        return $Value.ToUniversalTime()
    }
    if ($Value -is [DateTime]) {
        return [DateTimeOffset]::new($Value.ToUniversalTime())
    }
    [DateTimeOffset]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal)
}
