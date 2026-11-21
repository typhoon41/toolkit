function Get-ReleaseNoteEntry {
    param(
        [Parameter(Mandatory)] $Client,
        [AllowEmptyCollection()] [object[]] $Commits = @(),
        [AllowEmptyCollection()] [string[]] $Scope = @(),
        [switch] $SkipPullRequests
    )
    $fileCache = @{}
    foreach ($commit in @($Commits)) {
        if (Test-IgnoredCommit -Subject $commit.Subject -ParentCount 1) {
            continue
        }
        $pullRequest = if ($SkipPullRequests) { $null } else { Get-MergedPullRequest -Client $Client -Commit $commit.Hash }
        if ($pullRequest) {
            Get-PullRequestNoteEntry -Client $Client -PullRequest $pullRequest -MergeCommit $commit -Scope $Scope -FileCache $fileCache
            continue
        }
        New-ReleaseNoteEntry -Commit $commit.Hash -Subject $commit.Subject -ConventionalCommit (Get-ConventionalCommit $commit.Subject $commit.Body) `
            -Author $commit.Author -RepositoryUrl $Client.RepositoryUrl
    }
}
