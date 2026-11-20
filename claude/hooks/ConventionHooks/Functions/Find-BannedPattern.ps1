function Find-BannedPattern {
    # The rules the written text (or, for 'Path' rules, the file path) breaks, one hit per rule and matching line.
    # -FileContent is the whole file after the write; rules with ExcludeWhenFileMatches are checked against it,
    # or against the written text when it is not given. A rule with WhenProjectDependsOn applies only when that
    # package is in -ProjectPackage, the packages the file's project depends on.
    param(
        [Parameter(Mandatory)] [string] $Path,
        [AllowEmptyCollection()] [string[]] $Text = @(),
        [Parameter(Mandatory)] [object[]] $Rule,
        [AllowEmptyString()] [string] $FileContent = '',
        [AllowEmptyCollection()] [string[]] $ProjectPackage = @()
    )
    $extension = [IO.Path]::GetExtension($Path).ToLowerInvariant()
    $content = if ($FileContent) { $FileContent } else { $Text -join "`n" }
    # A timed-out exclusion counts as "not exempt", a timed-out line check as "no hit" (Test-PatternMatch).
    $applicable = $Rule | Where-Object {
        $_.Extensions -contains $extension -and
            (-not $_.WhenProjectDependsOn -or $ProjectPackage -contains $_.WhenProjectDependsOn) -and
            -not ($_.ExcludeWhenFileMatches -and (Test-PatternMatch -Pattern $_.ExcludeWhenFileMatches -Text $content))
    }
    foreach ($candidate in $applicable) {
        $lines = if ($candidate.Target -eq 'Path') { @($Path) } else { @($Text | ForEach-Object { $_ -split '\r?\n' }) }
        foreach ($line in $lines | Where-Object { Test-PatternMatch -Pattern $candidate.Pattern -Text $_ } | Select-Object -Unique) {
            [pscustomobject]@{
                RuleId  = $candidate.Id
                Line    = $line.Trim()
                Message = $candidate.Message
                Skill   = $candidate.Skill
            }
        }
    }
}
