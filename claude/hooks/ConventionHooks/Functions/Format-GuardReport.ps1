function Format-GuardReport {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [object[]] $Hit
    )
    $entries = foreach ($item in $Hit) {
        $owner = if ($item.Skill) { " (skill $($item.Skill))" } else { '' }
        "- $($item.RuleId): $($item.Message)$owner`n    $($item.Line)"
    }
    $lines = @("Banned patterns in what was just written to $($Path):") + @($entries) +
        @('Fix them now, unless the user asked for this or the project disables the rule in .claude/conventions.json.')
    $lines -join "`n"
}
