function Find-UnitRelease {
    param([Parameter(Mandatory)] $Context, [AllowEmptyCollection()] [object[]] $Releases = @())
    $same = @(@($Releases) | Where-Object {
        $tag = ConvertTo-ReleaseTag -TagName $_.tag_name -Prefix $Context.Prefix
        $tag -and $tag.Version.Text -eq $Context.Candidate.Text
    })
    $conflict = @($same | Where-Object { $_.tag_name -cne $Context.Tag })
    if ($conflict.Count -gt 0) {
        throw "Release '$($conflict[0].tag_name)' already uses version $($Context.Candidate.Text) under a different tag spelling."
    }
    if ($same.Count -gt 1) {
        throw "More than one release exists for $($Context.Tag); clean up the duplicates on GitHub."
    }
    if ($same.Count -eq 1) {
        return $same[0]
    }
    $null
}
