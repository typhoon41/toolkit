function New-UnitReleaseNote {
    <#
        Release notes for one unit of a release plan, from its previous tag (exclusive) to -Ref, limited to
        the unit's paths. Returns @{ Markdown; Text; EntryCount; Range }.
    #>
    param(
        [Parameter(Mandatory)] $UnitPlan,
        [Parameter(Mandatory)] $Client,
        [string] $Ref = 'HEAD',
        [switch] $SkipPullRequests
    )
    $range = if ($UnitPlan.previousTag) { "$($UnitPlan.previousTag)..$Ref" } else { $Ref }
    $scope = @($UnitPlan.paths)
    $commits = @(Get-FirstParentCommit -Range $range -Scope $scope)
    $entries = @(Get-ReleaseNoteEntry -Client $Client -Commits $commits -Scope $scope -SkipPullRequests:$SkipPullRequests)

    $compareUrl = if ($UnitPlan.previousTag) { "$($Client.RepositoryUrl)/compare/$($UnitPlan.previousTag)...$($UnitPlan.tag)" } else { '' }
    $releaseUrl = "$($Client.RepositoryUrl)/releases/tag/$($UnitPlan.tag)"
    [pscustomobject]@{
        Markdown   = ConvertTo-ReleaseNotesMarkdown -Entries $entries -CompareUrl $compareUrl
        Text       = ConvertTo-ReleaseNotesText -Entries $entries -ReleaseUrl $releaseUrl
        EntryCount = $entries.Count
        Range      = $range
    }
}
