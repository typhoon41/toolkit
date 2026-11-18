function Get-PullRequestNoteEntry {
    <#
        Entries for one merged pull request. Inner commits = the PR's commits without merge and
        fixup!/squash!/amend! commits; in scope = inner commits touching -Scope (all of them for an empty scope).
          at least one inner commit is conventional -> every in-scope inner commit, newest first:
                                                       conventional ones in their section, the others in Chores
          no inner commit is conventional            -> the PR's title (as it is on GitHub now), if any inner
                                                       commit is in scope; a non-conventional title is a chore
          inner commits exist but none is in scope   -> nothing (the PR belongs to another unit)
          GitHub can't list the commits (over 250)   -> the PR's title, with a warning
        The title needs no path check of its own when there are no inner commits to check: -MergeCommit comes from
        `git log --first-parent -- <unit paths>` (Get-ReleaseNoteEntry), so the PR's merge commit touched the unit.
    #>
    param(
        [Parameter(Mandatory)] $Client,
        [Parameter(Mandatory)] $PullRequest,
        [Parameter(Mandatory)] $MergeCommit,
        [AllowEmptyCollection()] [string[]] $Scope = @(),
        [Parameter(Mandatory)] [hashtable] $FileCache
    )
    $titleEntry = @{
        Commit = $MergeCommit.Hash; Subject = $PullRequest.title; ConventionalCommit = Get-ConventionalCommit -Subject $PullRequest.title
        Author = $MergeCommit.Author; PullRequestNumber = $PullRequest.number; RepositoryUrl = $Client.RepositoryUrl
    }
    try {
        $commits = Get-PullRequestCommit -Client $Client -PullRequest $PullRequest
    }
    catch {
        Write-PipelineIssue -Type warning -Message "$($_.Exception.Message) Using the title of PR #$($PullRequest.number) instead."
        return New-ReleaseNoteEntry @titleEntry
    }
    [array]::Reverse($commits)
    $inner = @($commits | ForEach-Object { ConvertTo-InnerCommit $_ } | Where-Object { -not $_.IsIgnored })
    if ($inner.Count -eq 0) {
        return New-ReleaseNoteEntry @titleEntry
    }
    $inScope = @($inner | Where-Object {
        @($Scope).Count -eq 0 -or (Test-PathInScope -FilePaths (Get-GitHubCommitFile -Client $Client -Commit $_.Sha -Cache $FileCache) -Scope $Scope)
    })
    if ($inScope.Count -eq 0) {
        return
    }
    if (-not @($inner | Where-Object { $_.Conventional })) {
        return New-ReleaseNoteEntry @titleEntry
    }
    foreach ($commit in $inScope) {
        New-ReleaseNoteEntry -Commit $commit.Sha -Subject $commit.Subject -ConventionalCommit $commit.Conventional `
            -Author $commit.Author -PullRequestNumber $PullRequest.number -RepositoryUrl $Client.RepositoryUrl
    }
}
