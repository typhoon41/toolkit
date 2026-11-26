function Set-ReleaseMarker {
    # The marker is written once and never touched again, so no failure can un-mark the draft.
    param([Parameter(Mandatory)] $Context, [Parameter(Mandatory)] $Release)
    $now = [DateTimeOffset]::UtcNow
    if (-not (Get-ReleaseAsset -Context $Context -Release $Release -Marker)) {
        Add-ReleaseStateAsset -Context $Context -Release $Release -Name ([ReleaseStateName]::Marker) -Content @{
            version = $Context.Candidate.Text; commit = $Context.Commit; state = 'publishing'; at = $now.ToString('o')
        }
        Write-ReleaseLog "Marked $($Context.Tag) as publishing."
    }
    Add-ReleaseStateAsset -Context $Context -Release $Release -Name ([ReleaseStateName]::Attempt($now)) -Content @{
        version = $Context.Candidate.Text; commit = $Context.Commit; attemptAt = $now.ToString('o')
    }
}
