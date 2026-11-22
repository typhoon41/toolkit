function Get-HighestMajorVersion {
    # The highest major version one range alternative allows; nothing when it has no upper bound (>=19, *) or cannot
    # be read (workspace:*, latest, $(Version)). Reads npm comparators (^ ~ = < <= > >=, 19.x, 18 - 19) and NuGet
    # versions and intervals ([a,b), (,b], [a,), [a]); several comparators narrow to the smallest upper bound.
    param([AllowEmptyString()] [string] $Range = '')
    $version = '[vV]?(?<major>\d+)(?:\.(?<minor>\d+|[xX*]))?(?:\.(?<patch>\d+|[xX*]))?(?:[-+][\w.-]*)?'
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
            $minor = if ($Matches.ContainsKey('minor')) { $Matches['minor'] } else { '0' }
            $patch = if ($Matches.ContainsKey('patch')) { $Matches['patch'] } else { '0' }
            $belowMajor = ($minor -notmatch '^\d+$' -or [int]$minor -eq 0) -and ($patch -notmatch '^\d+$' -or [int]$patch -eq 0)
            $uppers += if ($belowMajor) { $major - 1 } else { $major }
        }
        elseif ($operator -notin '>', '>=') {
            $uppers += $major
        }
    }
    if ($uppers.Count -gt 0) {
        ($uppers | Measure-Object -Minimum).Minimum
    }
}
