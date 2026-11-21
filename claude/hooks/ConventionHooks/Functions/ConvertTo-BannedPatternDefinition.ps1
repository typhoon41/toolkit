function ConvertTo-BannedPatternDefinition {
    # A project rule from .claude/conventions.json (camelCase JSON) in the shape of a BannedPatterns.psd1 entry.
    param([Parameter(Mandatory)] [AllowNull()] [object] $Rule)
    $definition = @{
        Id         = [string](Get-JsonProperty -Object $Rule -Name 'id' -Default '')
        Extensions = @(Get-JsonProperty -Object $Rule -Name 'extensions' -Default @() | ForEach-Object { ([string]$_).ToLowerInvariant() })
        Pattern    = [string](Get-JsonProperty -Object $Rule -Name 'pattern' -Default '')
        Message    = [string](Get-JsonProperty -Object $Rule -Name 'message' -Default '')
        Skill      = [string](Get-JsonProperty -Object $Rule -Name 'skill' -Default '')
    }
    foreach ($optional in 'target', 'whenProjectDependsOn', 'excludeWhenFileMatches') {
        $value = Get-JsonProperty -Object $Rule -Name $optional
        if ($null -ne $value) {
            $definition[$optional.Substring(0, 1).ToUpperInvariant() + $optional.Substring(1)] = [string]$value
        }
    }
    $definition
}
