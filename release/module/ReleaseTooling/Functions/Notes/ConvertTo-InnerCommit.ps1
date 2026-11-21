function ConvertTo-InnerCommit {
    param([Parameter(Mandatory)] $Commit)
    $subject, $body = ([string]$Commit.commit.message) -split '\r?\n', 2
    $subject = $subject.Trim()
    [pscustomobject]@{
        Sha          = $Commit.sha
        Subject      = $subject
        Author       = $Commit.commit.author.name
        IsIgnored    = Test-IgnoredCommit -Subject $subject -ParentCount @($Commit.parents).Count
        Conventional = Get-ConventionalCommit -Subject $subject -Body ([string]$body)
    }
}
