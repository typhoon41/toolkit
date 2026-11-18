function Wait-UnitFeedPublication {
    <#
        Waits until every primary package of the context is on its feed as this build's exact package. A
        foreign package fails at once; an absent one is re-checked every -IntervalSeconds until -TimeoutMinutes
        have passed, because a feed (nuget.org especially) indexes a push only after some minutes.
    #>
    param(
        [Parameter(Mandatory)] $Context,
        [int] $TimeoutMinutes = 15,
        [int] $IntervalSeconds = 30
    )
    $deadline = [DateTimeOffset]::UtcNow.AddMinutes($TimeoutMinutes)
    while ($true) {
        $states = Get-UnitFeedState -UnitPlan $Context.Unit -Files $Context.Files -Commit $Context.Commit
        if ($states.Count -eq 0) {
            throw "No primary package for $($Context.Tag); nothing proves the feed push happened."
        }
        $foreign = @($states | Where-Object State -eq 'Foreign')
        if ($foreign.Count -gt 0) {
            throw ("The feed holds a different package under $($foreign[0].Label) ($($foreign[0].Detail)), so $($Context.Tag) " +
                   'cannot be published. A maintainer abandons it (docs/RECOVERY.md, Abandon); then bump the version.')
        }
        $absent = @($states | Where-Object State -eq 'Absent')
        if ($absent.Count -eq 0) {
            return
        }
        if ([DateTimeOffset]::UtcNow -ge $deadline) {
            throw ("$($absent.Label -join ', ') not on the feed yet, so $($Context.Tag) stays a draft. If the push step succeeded, " +
                   'the feed is still indexing: use "Rerun failed jobs" in a few minutes.')
        }
        Write-ReleaseLog "Waiting for the feed to list $($absent.Label -join ', ')..."
        Start-Sleep -Seconds $IntervalSeconds
    }
}
