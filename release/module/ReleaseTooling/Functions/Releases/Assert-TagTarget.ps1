function Assert-TagTarget {
    # Fails when the tag exists on GitHub and points elsewhere; returns the commit it points to, or $null.
    param([Parameter(Mandatory)] $Context)
    $commit = Get-GitHubTagCommit -Client $Context.Client -Tag $Context.Tag
    if ($commit -and $commit -ne $Context.Commit) {
        throw "Tag $($Context.Tag) already exists and points to $commit, not $($Context.Commit)."
    }
    $commit
}
