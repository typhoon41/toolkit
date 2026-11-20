function Read-BannedPatternRule {
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
            WhenProjectDependsOn   = if ($rule.ContainsKey('WhenProjectDependsOn')) { $rule.WhenProjectDependsOn } else { $null }
            Message                = $rule.Message
            Skill                  = $rule.Skill
        }
    }
}
