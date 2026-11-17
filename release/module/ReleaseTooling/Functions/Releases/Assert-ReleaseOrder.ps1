function Assert-ReleaseOrder {
    # Published releases on GitHub plus release tags in the clone: the context's version must be the highest.
    param([Parameter(Mandatory)] $Context, [AllowEmptyCollection()] [object[]] $Releases = @())
    $known = @(@($Releases) | Where-Object { -not $_.draft } | ForEach-Object { ConvertTo-ReleaseTag -TagName $_.tag_name -Prefix $Context.Prefix } | Where-Object { $_ })
    $known += @(Get-ReleaseTag -Prefix $Context.Prefix)
    $higher = @($known | Where-Object {
        $_.Version.Text -ne $Context.Candidate.Text -and (Compare-ReleaseVersion $_.Version $Context.Candidate) -ge 0
    })
    if ($higher.Count -gt 0) {
        $top = Get-HighestRelease $higher
        throw "$($top.Tag) is already released, so $($Context.Tag) can no longer be published. Bump the version."
    }
}
