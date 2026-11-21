function Read-ReleaseConfiguration {
    param(
        [Parameter(Mandatory)] [string] $RepositoryRoot,
        [string] $Path = 'release.json'
    )
    $full = Join-Path $RepositoryRoot $Path
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        throw "No $Path in the repository root. Add one that lists the release units (docs/ADOPTING.md)."
    }
    $document = Get-Content -LiteralPath $full -Raw | ConvertFrom-Json -AsHashtable
    $definitions = @($document['units'])
    if ($definitions.Count -eq 0 -or $null -eq $definitions[0]) {
        throw "$Path has no units."
    }

    $units = @(foreach ($definition in $definitions) {
        ConvertTo-ReleaseUnit -Definition $definition -IsOnlyUnit:($definitions.Count -eq 1)
    })
    $names = @($units.Name)
    $duplicate = $names | Group-Object | Where-Object Count -gt 1 | Select-Object -First 1
    if ($duplicate) {
        throw "$Path lists unit '$($duplicate.Name)' more than once."
    }
    $prefixes = @($units.TagPrefix)
    if (@($prefixes | Select-Object -Unique).Count -ne $prefixes.Count) {
        throw "$Path gives two units the same tag prefix; set a distinct 'tagPrefix' on each."
    }

    $runNameUnit = if ($document['runNameUnit']) { [string]$document['runNameUnit'] } else { '' }     # '' = decided per build
    if ($runNameUnit -and $runNameUnit -notin $names) {
        throw "$Path names runNameUnit '$runNameUnit', which is not one of its units."
    }
    [pscustomobject]@{ Units = $units; RunNameUnit = $runNameUnit }
}
