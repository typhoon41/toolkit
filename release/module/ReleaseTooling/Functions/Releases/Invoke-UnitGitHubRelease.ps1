function Invoke-UnitGitHubRelease {
    param(
        [Parameter(Mandatory)] [ValidateSet('Prepare', 'Publish', 'Abandon', 'Restore')] [string] $Action,
        [Parameter(Mandatory)] $Client,
        [Parameter(Mandatory)] $UnitPlan,
        [Parameter(Mandatory)] [string] $Commit,
        [Parameter(Mandatory)] [string] $PackagesPath,
        [string] $NotesFile,
        [int] $MinimumAgeMinutes = 60,
        [int] $FeedWaitMinutes = 15
    )
    if (-not $PackagesPath) {
        throw "-PackagesPath is required for unit '$($UnitPlan.name)'."
    }
    $files = Get-UnitPackageFile -UnitPlan $UnitPlan -PackagesPath $PackagesPath -Require
    foreach ($file in @($files | Where-Object { $_.Extension -in '.nupkg', '.snupkg' })) {
        $recorded = (Read-PackageNuspec $file.FullName).Commit
        if ($recorded -ne $Commit) {
            throw "$($file.Name) records commit '$recorded', expected $Commit."
        }
    }
    $context = New-GitHubReleaseContext -Client $Client -UnitPlan $UnitPlan -Commit $Commit -Files $files
    $releases = Get-GitHubRelease -Client $Client
    $release = Find-UnitRelease -Context $context -Releases $releases
    Assert-NoUnfinishedRelease -Context $context -Releases $releases

    $publicationStarted = Test-PublicationStarted -Context $context -VersionText $context.Candidate.Text -Release $release
    Assert-ReleaseCommit -Context $context -Release $release -PublicationStarted $publicationStarted -Action $Action

    if ($release -and -not $release.draft) {
        if ($Action -eq 'Abandon') {
            throw "Release $($context.Tag) is already published; it cannot be abandoned."
        }
        Confirm-PublishedRelease -Context $context -Release $release
        return
    }
    if ($release -and $Action -ne 'Abandon' -and (Test-ReleaseSuperseded -Context $context -Release $release)) {
        throw "Release $($context.Tag) was superseded by a maintainer and must not be published. Bump the version."
    }
    switch ($Action) {
        'Prepare' { Invoke-ReleasePrepare -Context $context -Release $release -Releases $releases -PublicationStarted $publicationStarted -NotesFile $NotesFile }
        'Publish' { Invoke-ReleasePublish -Context $context -Release $release -FeedWaitMinutes $FeedWaitMinutes }
        'Abandon' { Invoke-ReleaseAbandon -Context $context -Release $release -MinimumAgeMinutes $MinimumAgeMinutes }
        'Restore' { Invoke-ReleaseRestore -Context $context -Release $release -Releases $releases -NotesFile $NotesFile }
    }
}
