function Get-BooleanSetting {
    # A JSON true / false; an absent setting, or one of any other type ("false", 0, []), keeps the default - the
    # latter with a warning on stderr - so a typo never switches a strict hook off.
    param(
        [Parameter(Mandatory)] [AllowNull()] [object] $Object,
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [bool] $Default,
        [string] $Source = '.claude/conventions.json'
    )
    $value = Get-JsonProperty -Object $Object -Name $Name
    if ($null -eq $value) {
        return $Default
    }
    if ($value -is [bool]) {
        return $value
    }
    [Console]::Error.WriteLine("Ignoring $Name in ${Source}: expected true or false.")
    $Default
}
