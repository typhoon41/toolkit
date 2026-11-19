function Find-BannedPattern {
    # The rules the written text (or, for 'Path' rules, the file path) breaks, one hit per rule and matching line.
    param(
        [Parameter(Mandatory)] [string] $Path,
        [AllowEmptyCollection()] [string[]] $Text = @(),
        [Parameter(Mandatory)] [object[]] $Rule
    )
    $extension = [IO.Path]::GetExtension($Path).ToLowerInvariant()
    $applicable = $Rule | Where-Object { $_.Extensions -contains $extension -and -not ($_.ExcludePath -and $_.ExcludePath.IsMatch($Path)) }
    foreach ($candidate in $applicable) {
        $lines = if ($candidate.Target -eq 'Path') { @($Path) } else { @($Text | ForEach-Object { $_ -split '\r?\n' }) }
        foreach ($line in $lines | Where-Object { $candidate.Pattern.IsMatch($_) } | Select-Object -Unique) {
            [pscustomobject]@{
                RuleId  = $candidate.Id
                Line    = $line.Trim()
                Message = $candidate.Message
                Skill   = $candidate.Skill
            }
        }
    }
}
