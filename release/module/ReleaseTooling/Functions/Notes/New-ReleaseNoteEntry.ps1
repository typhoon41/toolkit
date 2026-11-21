function New-ReleaseNoteEntry {
    param(
        [Parameter(Mandatory)] [string] $Commit,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Subject,
        [AllowNull()] $ConventionalCommit,
        [AllowEmptyString()] [string] $Author,
        [int] $PullRequestNumber,
        [Parameter(Mandatory)] [string] $RepositoryUrl
    )
    $subjectText = $Subject.Trim()
    if ($PullRequestNumber -gt 0 -and $subjectText -notmatch "\(#$PullRequestNumber\)") {
        $subjectText += " (#$PullRequestNumber)"
    }
    $authorSuffix = if ($Author) { " ($Author)" } else { '' }
    [pscustomobject]@{
        Section  = Get-ReleaseNoteSection $ConventionalCommit
        Markdown = "- [``$($Commit.Substring(0, 7))``]($RepositoryUrl/commit/$Commit) $subjectText$authorSuffix"
        Text     = "- $subjectText"
    }
}
