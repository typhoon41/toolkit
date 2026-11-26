function Assert-TagTarget {
    param([Parameter(Mandatory)] $Context, [string] $MissingReason)
    $commit = Get-GitHubTagCommit -Client $Context.Client -Tag $Context.Tag
    if ($commit -and $commit -ne $Context.Commit) {
        throw "Tag $($Context.Tag) already exists and points to $commit, not $($Context.Commit)."
    }
    if (-not $commit -and $MissingReason) {
        throw $MissingReason
    }
    $commit
}
