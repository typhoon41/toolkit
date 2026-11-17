<#
.SYNOPSIS
    Checks that a GitHub PR's title and commits follow the commit convention (Conventional Commits).

.DESCRIPTION
    Warn-only by default: a commit that doesn't follow the convention still ships, as a chore in the release
    notes. With -Enforce every such commit, and the title, fail the check.
    Ignored: merge commits and fixup!/squash!/amend! commits.

    Runs in PR validation with a READ-ONLY token (GITHUB_TOKEN), or none at all for public repositories.
    Everything printed passes through Write-ReleaseLog / Write-PipelineIssue, which neutralise logging commands
    hidden in titles or commit messages.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [ValidateRange(1, [int]::MaxValue)] [int] $PullRequestNumber,
    [string] $Repository,
    [switch] $Enforce,
    [string] $ApiUrl = 'https://api.github.com'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force

$examples = "Examples: 'feat: add retry policy', 'fix(parser): handle empty input', 'feat!: drop .NET 8'. " +
            "Allowed types: $((Get-AllowedCommitType) -join ', '). See docs/CONTRIBUTING.md."
$level = if ($Enforce) { 'error' } else { 'warning' }

try {
    if (-not $Repository) {
        $Repository = Get-GitHubRepositoryName
    }
    $client = New-GitHubClient -Repository $Repository -Token $env:GITHUB_TOKEN -ApiUrl $ApiUrl
    if (-not $client.HasToken) {
        Write-ReleaseLog 'No GitHub token available; using anonymous API access.'
    }
    $pullRequest = Invoke-GitHubApi -Client $client -Path "pulls/$PullRequestNumber"
    $failures = 0

    if (Get-ConventionalCommit -Subject $pullRequest.title) {
        Write-ReleaseLog "Title OK: $($pullRequest.title)"
    }
    else {
        Write-PipelineIssue -Type $level -Message "PR title '$($pullRequest.title)' doesn't follow the commit convention; if it is used in the release notes it lands in Chores. $examples"
        $failures++
    }

    foreach ($commit in Get-PullRequestCommit -Client $client -PullRequest $pullRequest) {
        $short = $commit.sha.Substring(0, 7)
        $subject, $body = ([string]$commit.commit.message) -split '\r?\n', 2
        $subject = $subject.Trim()
        if (Test-IgnoredCommit -Subject $subject -ParentCount @($commit.parents).Count) {
            Write-ReleaseLog "Skip    $short $subject"
        }
        elseif (Get-ConventionalCommit -Subject $subject -Body ([string]$body)) {
            Write-ReleaseLog "OK      $short $subject"
        }
        else {
            Write-PipelineIssue -Type $level -Message "Commit $short '$subject' doesn't follow the commit convention; it will be listed under Chores."
            $failures++
        }
    }

    if ($failures -gt 0 -and $Enforce) {
        Write-PipelineIssue -Type error -Message "$failures title/commit message(s) need rewording (git rebase -i, 'reword', force-push). $examples"
        exit 1
    }
}
catch {
    Write-PipelineIssue -Type error -Message $_.Exception.Message
    exit 1
}
