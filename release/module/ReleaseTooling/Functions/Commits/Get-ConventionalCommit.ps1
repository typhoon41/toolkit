function Get-ConventionalCommit {
    # Case-sensitive: "Feat:" is not a Conventional Commit.
    param(
        [AllowNull()] [AllowEmptyString()] [string] $Subject,
        [AllowNull()] [AllowEmptyString()] [string] $Body
    )
    $pattern = "^(?<type>$((Get-AllowedCommitType) -join '|'))(?:\((?<scope>[\w\-./ ]+)\))?(?<breaking>!)?: \S.*$"
    if (-not $Subject -or $Subject -cnotmatch $pattern) {
        return $null
    }
    [pscustomobject]@{
        Type     = $Matches['type']
        Scope    = if ($Matches.ContainsKey('scope')) { $Matches['scope'] } else { '' }
        Breaking = $Matches.ContainsKey('breaking') -or ($Body -and $Body -match '(?m)^BREAKING[ -]CHANGE:')
    }
}
