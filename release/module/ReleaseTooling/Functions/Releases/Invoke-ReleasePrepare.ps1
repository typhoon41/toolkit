function Invoke-ReleasePrepare {
    <#
        Creates or resumes the DRAFT release (no tag yet, invisible to users), sets its notes, makes its assets
        match this build, then writes the marker: from here on the draft is frozen and the feed push follows.
        A frozen draft is only verified; its notes, name and target stay as they are.
    #>
    param(
        [Parameter(Mandatory)] $Context,
        [AllowNull()] $Release,
        [AllowEmptyCollection()] [object[]] $Releases = @(),
        [Parameter(Mandatory)] [bool] $PublicationStarted,
        [string] $NotesFile
    )
    Assert-ReleaseOrder -Context $Context -Releases $Releases
    [void](Assert-TagTarget -Context $Context)

    if ($PublicationStarted -and -not $Release) {
        $state = Get-UnitFeedState -UnitPlan $Context.Unit -Files $Context.Files -Commit $Context.Commit
        $summary = ($state | ForEach-Object { "$($_.Label): $($_.State)" }) -join '; '
        $advice = if (@($state | Where-Object State -eq 'Foreign').Count -gt 0) { 'A FOREIGN package occupies the version: bump the version.' }
                  else { "This build's package(s) reached the feed without a draft: a maintainer runs -Action Restore with the COMPLETE original artifacts, then Prepare -> publish to the feed -> Publish (docs/RELEASING.md, 'Missing draft')." }
        throw "The feed already holds version $($Context.Candidate.Text) but GitHub has no draft release $($Context.Tag). Found on the feed: $summary. $advice"
    }
    if ($PublicationStarted) {
        Write-ReleaseLog "Resuming frozen draft release $($Context.Tag) (notes unchanged)"
        Sync-ReleaseAsset -Context $Context -Release $Release -VerifyOnly -FrozenReason (Get-FrozenReason $Context)
        Set-ReleaseMarker -Context $Context -Release $Release
        Write-ReleaseLog "Draft release $($Context.Tag) is ready."
        return
    }

    $payload = New-ReleasePayload -Context $Context -Body (Get-ReleaseBody -Context $Context -NotesFile $NotesFile)
    if ($Release -and $Release.target_commitish -ne $Context.Commit) {
        Write-ReleaseLog "Deleting abandoned draft for $($Context.Tag) (it targets $($Release.target_commitish), nothing was pushed)"
        Invoke-GitHubApi -Client $Context.Client -Method Delete -Path "releases/$($Release.id)" | Out-Null
        $Release = $null
    }
    $Release = if ($Release) {
        Write-ReleaseLog "Resuming draft release $($Context.Tag)"
        Invoke-GitHubApi -Client $Context.Client -Method Patch -Path "releases/$($Release.id)" -Body $payload
    }
    else {
        Write-ReleaseLog "Creating draft release $($Context.Tag)"
        Invoke-GitHubApi -Client $Context.Client -Method Post -Path 'releases' -Body $payload
    }
    Sync-ReleaseAsset -Context $Context -Release $Release
    Set-ReleaseMarker -Context $Context -Release $Release
    Write-ReleaseLog "Draft release $($Context.Tag) is ready."
}
