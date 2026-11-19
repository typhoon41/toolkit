function Find-BannedPattern {
    # The rules the written text (or, for 'Path' rules, the file path) breaks, one hit per rule and matching line.
    # -FileContent is the whole file after the write; rules with ExcludeWhenFileMatches are checked against it,
    # or against the written text when it is not given.
    param(
        [Parameter(Mandatory)] [string] $Path,
        [AllowEmptyCollection()] [string[]] $Text = @(),
        [Parameter(Mandatory)] [object[]] $Rule,
        [AllowEmptyString()] [string] $FileContent = ''
    )
    $extension = [IO.Path]::GetExtension($Path).ToLowerInvariant()
    $content = if ($FileContent) { $FileContent } else { $Text -join "`n" }
    $applicable = $Rule | Where-Object {
        $_.Extensions -contains $extension -and -not ($_.ExcludeWhenFileMatches -and $_.ExcludeWhenFileMatches.IsMatch($content))
    }
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
