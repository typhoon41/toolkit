function ConvertTo-ReleaseTag {
    # The version is lowercased first, so an existing v1.3.0-Beta.1 still claims 1.3.0-beta.1.
    param([Parameter(Mandatory)] [string] $TagName, [Parameter(Mandatory)] [string] $Prefix)
    if (-not $TagName.StartsWith($Prefix, [StringComparison]::Ordinal)) {
        return $null
    }
    $version = ConvertTo-ReleaseVersion $TagName.Substring($Prefix.Length).ToLowerInvariant()
    if ($version) {
        [pscustomobject]@{ Tag = $TagName; Version = $version }
    }
}
