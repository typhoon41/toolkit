function ConvertTo-ReleaseVersion {
    <#
        Returns a version object, or $null when the text is not a canonical release version.
        Canonical = what NuGet uses for package identity, so a git tag, a NuGet and an npm version agree:
          - major.minor.patch, no leading zeros, each fits in Int32
          - optional prerelease: dot-separated lowercase identifiers (alpha, beta.2, rc.1); numeric
            identifiers have no leading zeros
          - no build metadata (+...)
    #>
    param([AllowNull()] [AllowEmptyString()] [string] $Text)
    $number = '(?:0|[1-9][0-9]*)'
    $identifier = '(?:0|[1-9][0-9]*|[0-9]*[a-z-][0-9a-z-]*)'
    $pattern = "^(?<major>$number)\.(?<minor>$number)\.(?<patch>$number)(?:-(?<prerelease>$identifier(?:\.$identifier)*))?$"
    if (-not $Text -or $Text -cnotmatch $pattern) {
        return $null
    }

    $major = 0
    $minor = 0
    $patch = 0
    $parsed = [int]::TryParse($Matches['major'], [ref]$major) -and
              [int]::TryParse($Matches['minor'], [ref]$minor) -and
              [int]::TryParse($Matches['patch'], [ref]$patch)
    if (-not $parsed) {
        return $null
    }
    $prerelease = if ($Matches.ContainsKey('prerelease')) { $Matches['prerelease'] } else { '' }

    [pscustomobject]@{
        Text         = $Text
        Major        = $major
        Minor        = $minor
        Patch        = $patch
        PreRelease   = $prerelease
        IsPrerelease = [bool]$prerelease
    }
}
