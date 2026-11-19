function Format-GuardReport {
    # The feedback Claude receives: one block per hit, naming the rule, the offending line and the owning skill.
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [object[]] $Hit
    )
    $entries = foreach ($item in $Hit) {
        "- $($item.RuleId): $($item.Message) (skill conventions:$($item.Skill))`n    $($item.Line)"
    }
    $lines = @("Banned patterns in what was just written to $($Path):") + @($entries) +
        @('Fix them now unless the user explicitly asked for this.')
    $lines -join "`n"
}
