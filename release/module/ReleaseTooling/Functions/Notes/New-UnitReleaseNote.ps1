function New-UnitReleaseNote {
    param(
        [Parameter(Mandatory)] $UnitPlan,
        [Parameter(Mandatory)] $Client,
        [string] $Ref = 'HEAD',
        [switch] $SkipPullRequests
    )
    $previousRelease = Get-PreviousReleaseReference -UnitPlan $UnitPlan
    $range = if ($previousRelease) { "$previousRelease..$Ref" } else { $Ref }
    $scope = @($UnitPlan.paths)
    $commits = @(Get-FirstParentCommit -Range $range -Scope $scope)
    $entries = @(Get-ReleaseNoteEntry -Client $Client -Commits $commits -Scope $scope -SkipPullRequests:$SkipPullRequests)

    $compareUrl = if ($previousRelease) { "$($Client.RepositoryUrl)/compare/$previousRelease...$($UnitPlan.tag)" } else { '' }
    $releaseUrl = "$($Client.RepositoryUrl)/releases/tag/$($UnitPlan.tag)"
    [pscustomobject]@{
        Markdown   = ConvertTo-ReleaseNotesMarkdown -Entries $entries -CompareUrl $compareUrl
        Text       = ConvertTo-ReleaseNotesText -Entries $entries -ReleaseUrl $releaseUrl
        EntryCount = $entries.Count
        Range      = $range
    }
}
