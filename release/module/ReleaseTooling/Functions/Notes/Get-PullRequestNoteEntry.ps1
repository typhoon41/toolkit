function Get-PullRequestNoteEntry {
    <#
        Entries for one merged pull request: one per Conventional Commit inside it (newest first, merge and
        fixup!/squash!/amend! commits skipped, commits outside -Scope skipped). When none remain, the PR's
        title as it is on GitHub now, so editing the squash message at merge time changes nothing. A title
        that doesn't follow the convention lands in Chores.
    #>
    param(
        [Parameter(Mandatory)] $Client,
        [Parameter(Mandatory)] $PullRequest,
        [Parameter(Mandatory)] $MergeCommit,
        [AllowEmptyCollection()] [string[]] $Scope = @(),
        [Parameter(Mandatory)] [hashtable] $FileCache
    )
    $inner = @()
    try {
        $commits = Get-PullRequestCommit -Client $Client -PullRequest $PullRequest
        [array]::Reverse($commits)
        $inner = @(foreach ($commit in $commits) {
            $subject, $body = ([string]$commit.commit.message) -split '\r?\n', 2
            $subject = $subject.Trim()
            if (Test-IgnoredCommit -Subject $subject -ParentCount @($commit.parents).Count) {
                continue
            }
            $conventional = Get-ConventionalCommit -Subject $subject -Body ([string]$body)
            if (-not $conventional) {
                continue
            }
            if (@($Scope).Count -gt 0 -and -not (Test-PathInScope -FilePaths (Get-GitHubCommitFile -Client $Client -Commit $commit.sha -Cache $FileCache) -Scope $Scope)) {
                continue
            }
            New-ReleaseNoteEntry -Commit $commit.sha -Subject $subject -ConventionalCommit $conventional `
                -Author $commit.commit.author.name -PullRequestNumber $PullRequest.number -RepositoryUrl $Client.RepositoryUrl
        })
    }
    catch {
        Write-PipelineIssue -Type warning -Message "$($_.Exception.Message) Using the title of PR #$($PullRequest.number) instead."
    }
    if ($inner.Count -gt 0) {
        return $inner
    }
    New-ReleaseNoteEntry -Commit $MergeCommit.Hash -Subject $PullRequest.title -ConventionalCommit (Get-ConventionalCommit -Subject $PullRequest.title) `
        -Author $MergeCommit.Author -PullRequestNumber $PullRequest.number -RepositoryUrl $Client.RepositoryUrl
}
