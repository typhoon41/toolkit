function Get-ReleaseNoteEntry {
    <#
        Release note entries for first-parent commits of the release branch:
          merged through a PR -> the PR's Conventional Commits, or its title (Get-PullRequestNoteEntry)
          pushed directly     -> the commit itself
        With -SkipPullRequests (offline previews) every commit stands for itself.
    #>
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
