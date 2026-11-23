function Read-BannedPatternRule {
    # Bundled rules name a skill of this plugin, reported as <plugin>:<skill>; project rules (.claude/conventions.json)
    # name any skill or none. A disabled id drops either kind. An incomplete or invalid project rule is skipped with a
    # warning on stderr, so a project's typo never breaks the hook.
    param(
        [Parameter(Mandatory)] [string] $Path,
        [AllowEmptyCollection()] [hashtable[]] $ProjectRule = @(),
        [AllowEmptyCollection()] [string[]] $DisabledRuleId = @(),
        [string] $Plugin = (Get-PluginName)
    )
    foreach ($rule in (Import-PowerShellDataFile -LiteralPath $Path).Rules) {
        if ($DisabledRuleId -notcontains $rule.Id) {
            $bundled = $rule.Clone()
            $bundled.Skill = "${Plugin}:$($rule.Skill)"
            ConvertTo-BannedPatternRule -Rule $bundled
        }
    }
    foreach ($rule in $ProjectRule) {
        if ($DisabledRuleId -notcontains $rule.Id) {
            try {
                ConvertTo-BannedPatternRule -Rule $rule
            }
            catch {
                [Console]::Error.WriteLine("Ignoring project rule '$($rule.Id)': $($_.Exception.Message)")
            }
        }
    }
}
