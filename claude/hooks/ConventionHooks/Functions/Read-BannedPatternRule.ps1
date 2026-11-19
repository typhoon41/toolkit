function Read-BannedPatternRule {
    # The rules of BannedPatterns.psd1 as objects; Target defaults to 'Text', ExcludeWhenFileMatches to none.
    # Every regular expression gets a match timeout (see Test-PatternMatch).
    param([Parameter(Mandatory)] [string] $Path)
    $timeout = [TimeSpan]::FromSeconds(1)
    $options = [Text.RegularExpressions.RegexOptions]::None
    foreach ($rule in (Import-PowerShellDataFile -LiteralPath $Path).Rules) {
        [pscustomobject]@{
            Id                     = $rule.Id
            Extensions             = @($rule.Extensions)
            Target                 = if ($rule.ContainsKey('Target')) { $rule.Target } else { 'Text' }
            Pattern                = [regex]::new($rule.Pattern, $options, $timeout)
            ExcludeWhenFileMatches = if ($rule.ContainsKey('ExcludeWhenFileMatches')) { [regex]::new($rule.ExcludeWhenFileMatches, $options, $timeout) } else { $null }
            Message                = $rule.Message
            Skill                  = $rule.Skill
        }
    }
}
