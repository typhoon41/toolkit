function Assert-TagTarget {
    param([Parameter(Mandatory)] $Context)
    $commit = Get-GitHubTagCommit -Client $Context.Client -Tag $Context.Tag
    if ($commit -and $commit -ne $Context.Commit) {
        throw "Tag $($Context.Tag) already exists and points to $commit, not $($Context.Commit)."
    }
    $commit
}
