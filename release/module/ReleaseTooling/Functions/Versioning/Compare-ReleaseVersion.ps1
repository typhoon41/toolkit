function Compare-ReleaseVersion {
    param([Parameter(Mandatory)] $Left, [Parameter(Mandatory)] $Right)
    foreach ($part in 'Major', 'Minor', 'Patch') {
        $comparison = $Left.$part.CompareTo($Right.$part)
        if ($comparison -ne 0) {
            return [Math]::Sign($comparison)
        }
    }
    if (-not $Left.PreRelease -and -not $Right.PreRelease) {
        return 0
    }
    if (-not $Left.PreRelease) {
        return 1
    }
    if (-not $Right.PreRelease) {
        return -1
    }

    $leftIdentifiers = $Left.PreRelease.Split('.')
    $rightIdentifiers = $Right.PreRelease.Split('.')
    for ($index = 0; $index -lt [Math]::Min($leftIdentifiers.Count, $rightIdentifiers.Count); $index++) {
        $comparison = Compare-PrereleaseIdentifier $leftIdentifiers[$index] $rightIdentifiers[$index]
        if ($comparison -ne 0) {
            return $comparison
        }
    }
    [Math]::Sign($leftIdentifiers.Count.CompareTo($rightIdentifiers.Count))
}
