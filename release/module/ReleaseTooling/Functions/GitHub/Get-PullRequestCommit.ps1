function Get-PullRequestCommit {
    # GitHub lists at most 250 commits of a pull request.
    param([Parameter(Mandatory)] $Client, [Parameter(Mandatory)] $PullRequest)
    $commits = @(Get-GitHubCollection -Client $Client -Path "pulls/$($PullRequest.number)/commits")
    if ($commits.Count -lt [int]$PullRequest.commits) {
        throw ("PR #$($PullRequest.number) has $($PullRequest.commits) commits but GitHub returned only " +
               "$($commits.Count) (the API returns at most 250).")
    }
    , $commits
}
