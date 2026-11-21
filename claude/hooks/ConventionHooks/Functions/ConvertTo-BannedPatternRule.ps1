function ConvertTo-BannedPatternRule {
    # A BannedPatterns.psd1-shaped entry with its patterns compiled; matching times out after a second.
    param([Parameter(Mandatory)] [hashtable] $Rule)
    foreach ($required in 'Id', 'Extensions', 'Pattern', 'Message') {
        if (-not $Rule.ContainsKey($required) -or -not $Rule[$required]) {
            throw "the rule has no $required."
        }
    }
    $timeout = [TimeSpan]::FromSeconds(1)
    $options = [Text.RegularExpressions.RegexOptions]::None
    [pscustomobject]@{
        Id                     = $Rule.Id
        Extensions             = @($Rule.Extensions)
        Target                 = if ($Rule.ContainsKey('Target')) { $Rule.Target } else { 'Text' }
        Pattern                = [regex]::new($Rule.Pattern, $options, $timeout)
        ExcludeWhenFileMatches = if ($Rule.ContainsKey('ExcludeWhenFileMatches')) { [regex]::new($Rule.ExcludeWhenFileMatches, $options, $timeout) } else { $null }
        WhenProjectDependsOn   = if ($Rule.ContainsKey('WhenProjectDependsOn')) { $Rule.WhenProjectDependsOn } else { $null }
        Message                = $Rule.Message
        Skill                  = if ($Rule.ContainsKey('Skill')) { $Rule.Skill } else { '' }
    }
}
