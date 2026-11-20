function ConvertTo-ReleaseVersion {
    # Canonical means NuGet package identity, so a git tag, a NuGet and an npm version agree.
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
