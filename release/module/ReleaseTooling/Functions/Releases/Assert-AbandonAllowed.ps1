function Assert-AbandonAllowed {
    param(
        [Parameter(Mandatory)] $Context,
        [Parameter(Mandatory)] $Release,
        [Parameter(Mandatory)] $Marker,
        [AllowEmptyCollection()] [string[]] $Published = @(),
        [AllowEmptyCollection()] [string[]] $Foreign = @(),
        [int] $MinimumAgeMinutes = 60
    )
    if ($Foreign.Count -eq 0 -and $Published.Count -gt 0) {
        throw ("Cannot abandon $($Context.Tag): this build's package(s) $($Published -join ', ') ARE on the feed and no version " +
               'collision exists. Complete the release instead (re-run its job, or the reconciliation procedure).')
    }
    if ($Foreign.Count -eq 0) {
        $age = [DateTimeOffset]::UtcNow - (Get-LatestAttemptTime -Context $Context -Release $Release -Marker $Marker)
        if ($age.TotalMinutes -lt $MinimumAgeMinutes) {
            throw ("Nothing is on the feed yet, but the latest push attempt was only $([int]$age.TotalMinutes) min ago; it may " +
                   "still be indexing. Wait until $MinimumAgeMinutes min have passed (or pass -MinimumAgeMinutes) and retry.")
        }
        Write-ReleaseLog "Nothing reached the feed for $($Context.Tag); the latest push attempt was $([int]$age.TotalMinutes) min ago."
        return
    }
    Write-ReleaseLog "Version collision proven for: $($Foreign -join ', ')."
    if ($Published.Count -gt 0) {
        Write-PipelineIssue -Type warning -Message ("These packages of $($Context.Tag) ARE published and will stay there without a " +
            "GitHub release: $($Published -join ', '). Consumers can install them; mention this in the next release's notes.")
    }
}
