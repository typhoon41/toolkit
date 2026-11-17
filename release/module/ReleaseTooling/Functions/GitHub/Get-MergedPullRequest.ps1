function Get-MergedPullRequest {
    # The full pull request that merged a commit into the release branch, or $null for a direct push.
    param([Parameter(Mandatory)] $Client, [Parameter(Mandatory)] [string] $Commit)
    $pullRequests = @(Invoke-GitHubApi -Client $Client -Path "commits/$Commit/pulls" | Where-Object { $_.merged_at })
    $match = @(@($pullRequests | Where-Object { $_.merge_commit_sha -eq $Commit }) + $pullRequests) | Select-Object -First 1
    if (-not $match) {
        return $null
    }
    Invoke-GitHubApi -Client $Client -Path "pulls/$($match.number)"     # full object: title, commit count
}
