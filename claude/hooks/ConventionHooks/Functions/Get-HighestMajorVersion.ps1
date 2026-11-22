function Get-HighestMajorVersion {
    # The highest major version one range alternative allows; nothing when it has no upper bound (>=19, *) or cannot
    # be read (workspace:*, latest, $(Version)). Reads npm comparators (^ ~ = < <= > >=, 19.x, 18 - 19) and NuGet
    # versions (up to four parts, 1.0.0.0) and intervals ([a,b), (,b], [a,), [a]); several comparators narrow to the
    # smallest upper bound.
    param([AllowEmptyString()] [string] $Range = '')
    $part = '(?:\.(?<{0}>\d+|[xX*]))?'
    $version = '[vV]?(?<major>\d+)' + ($part -f 'minor') + ($part -f 'patch') + ($part -f 'revision') + '(?:[-+][\w.-]*)?'
    $text = $Range.Trim()
    if ($text -match '^[\[(][^,\])]*,\s*(?<upper>[^\])]*?)\s*(?<close>[\])])$') {
        if (-not $Matches.upper) {
            return
        }
        $text = if ($Matches.close -eq ')') { "<$($Matches.upper)" } else { "<=$($Matches.upper)" }
    }
    elseif ($text -match '^\[\s*(?<exact>[^,\]]+?)\s*\]$') {
        $text = "=$($Matches.exact)"
    }
    elseif ($text -match '^\S+\s+-\s+(?<high>\S+)$') {
        $text = "<=$($Matches.high)"
    }
    $uppers = @()
    foreach ($comparator in ($text -split '\s+' | Where-Object { $_ -and $_ -notin '*', 'x', 'X' })) {
        if ($comparator -notmatch "^(?<operator><=|<|>=|>|=|\^|~)?$version$") {
            return
        }
        $operator = if ($Matches.ContainsKey('operator')) { $Matches['operator'] } else { '' }
        $major = [int]$Matches['major']
        if ($operator -eq '<') {
            # '<20', '<20.0.0', '<20.x' and '<20.0.0.0' all stop below major 20; '<20.1' or '<20.0.0.1' allow some of it.
            $trailing = @('minor', 'patch', 'revision' | ForEach-Object { if ($Matches.ContainsKey($_)) { $Matches[$_] } })
            $nonZero = @($trailing | Where-Object { $_ -match '^\d+$' -and [int]$_ -ne 0 })
            $uppers += if ($nonZero.Count -eq 0) { $major - 1 } else { $major }
        }
        elseif ($operator -notin '>', '>=') {
            $uppers += $major
        }
    }
    if ($uppers.Count -gt 0) {
        ($uppers | Measure-Object -Minimum).Minimum
    }
}
