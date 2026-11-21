function Get-HighestRelease {
    param([AllowNull()] [AllowEmptyCollection()] [object[]] $Releases)
    $highest = $null
    foreach ($release in @($Releases)) {
        if ($null -eq $highest -or (Compare-ReleaseVersion $release.Version $highest.Version) -gt 0) {
            $highest = $release
        }
    }
    $highest
}
