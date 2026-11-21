function Set-ReleaseMarker {
    # The marker is written once and never touched again, so no failure can un-mark the draft.
    param([Parameter(Mandatory)] $Context, [Parameter(Mandatory)] $Release)
    $names = Get-ReleaseStateName
    $now = [DateTimeOffset]::UtcNow
    if (-not (Get-ReleaseAsset -Context $Context -Release $Release -Name $names.Marker)) {
        Add-ReleaseStateAsset -Context $Context -Release $Release -Name $names.Marker -Content @{
            version = $Context.Candidate.Text; commit = $Context.Commit; state = 'publishing'; at = $now.ToString('o')
        }
        Write-ReleaseLog "Marked $($Context.Tag) as publishing."
    }
    $attempt = "release-attempt-$($now.ToString('yyyyMMddTHHmmssZ'))-$([Guid]::NewGuid().ToString('n').Substring(0, 8)).json"
    Add-ReleaseStateAsset -Context $Context -Release $Release -Name $attempt -Content @{
        version = $Context.Candidate.Text; commit = $Context.Commit; attemptAt = $now.ToString('o')
    }
}
