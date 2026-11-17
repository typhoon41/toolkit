function Get-PullRequestCommit {
    # All commits of a pull request, oldest first, or throws when GitHub can't return them all (its limit is 250).
    param([Parameter(Mandatory)] $Client, [Parameter(Mandatory)] $PullRequest)
    $commits = @(Get-GitHubCollection -Client $Client -Path "pulls/$($PullRequest.number)/commits")
    if ($commits.Count -lt [int]$PullRequest.commits) {
        throw ("PR #$($PullRequest.number) has $($PullRequest.commits) commits but GitHub returned only " +
               "$($commits.Count) (the API returns at most 250).")
    }
    , $commits
}
