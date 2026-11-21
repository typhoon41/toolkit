function Invoke-ReleaseRestore {
    # Maintainer-only: the feed holds this build's packages but no draft exists (a push outside the pipeline, or a
    # deleted draft). Needs the complete original artifact set.
    param(
        [Parameter(Mandatory)] $Context,
        [AllowNull()] $Release,
        [AllowEmptyCollection()] [object[]] $Releases = @(),
        [string] $NotesFile
    )
    if ($Release -and (Get-ReleaseAsset -Context $Context -Release $Release -Name (Get-ReleaseStateName).Marker)) {
        throw "A frozen draft for $($Context.Tag) already exists; use Prepare."
    }
    if ($Release -and $Release.target_commitish -ne $Context.Commit) {
        throw "An unfinished draft for $($Context.Tag) targets $($Release.target_commitish), not $($Context.Commit). Delete it on GitHub (it carries no marker) and retry."
    }
    Assert-ReleaseOrder -Context $Context -Releases $Releases
    [void](Assert-TagTarget -Context $Context)
    $state = Get-UnitFeedState -UnitPlan $Context.Unit -Files $Context.Files -Commit $Context.Commit
    if (@($state | Where-Object State -eq 'Foreign').Count -gt 0) {
        throw "A FOREIGN package occupies version $($Context.Candidate.Text); Restore is impossible. Bump the version."
    }
    if (@($state | Where-Object State -eq 'Published').Count -eq 0) {
        throw "None of this build's packages is on the feed; nothing to restore. Run the normal pipeline instead."
    }

    $payload = New-ReleasePayload -Context $Context -Body (Get-ReleaseBody -Context $Context -NotesFile $NotesFile)
    $Release = if ($Release) {
        Write-ReleaseLog "Resuming interrupted restore of $($Context.Tag)"
        Invoke-GitHubApi -Client $Context.Client -Method Patch -Path "releases/$($Release.id)" -Body $payload
    }
    else {
        Invoke-GitHubApi -Client $Context.Client -Method Post -Path 'releases' -Body $payload
    }
    Sync-ReleaseAsset -Context $Context -Release $Release      # uploads what is missing, replaces what differs
    Set-ReleaseMarker -Context $Context -Release $Release      # written last: only a complete draft becomes frozen
    Write-ReleaseLog "Draft $($Context.Tag) restored and frozen. Now run Prepare -> publish to the feed -> Publish."
}
