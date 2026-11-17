function ConvertTo-ReleaseTag {
    <#
        A release tag is <prefix><canonical version>, e.g. v1.3.0 or Gmf.DDD.Common/v1.3.0-beta.1.
        Anything else (vNext, v1.2, v01.0.0) is not a release and returns $null. The version part is
        lowercased first, so an existing v1.3.0-Beta.1 still claims the identity 1.3.0-beta.1.
    #>
    param([Parameter(Mandatory)] [string] $TagName, [Parameter(Mandatory)] [string] $Prefix)
    if (-not $TagName.StartsWith($Prefix, [StringComparison]::Ordinal)) {
        return $null
    }
    $version = ConvertTo-ReleaseVersion $TagName.Substring($Prefix.Length).ToLowerInvariant()
    if ($version) {
        [pscustomobject]@{ Tag = $TagName; Version = $version }
    }
}
