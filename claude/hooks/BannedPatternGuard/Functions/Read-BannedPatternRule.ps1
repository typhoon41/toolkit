function Read-BannedPatternRule {
    # The rules of BannedPatterns.psd1 as objects; Target defaults to 'Text', ExcludePath to none.
    param([Parameter(Mandatory)] [string] $Path)
    foreach ($rule in (Import-PowerShellDataFile -LiteralPath $Path).Rules) {
        [pscustomobject]@{
            Id          = $rule.Id
            Extensions  = @($rule.Extensions)
            Target      = if ($rule.ContainsKey('Target')) { $rule.Target } else { 'Text' }
            Pattern     = [regex]::new($rule.Pattern)
            ExcludePath = if ($rule.ContainsKey('ExcludePath')) { [regex]::new($rule.ExcludePath) } else { $null }
            Message    = $rule.Message
            Skill      = $rule.Skill
        }
    }
}
