function Assert-ReleaseCommit {
    # A frozen draft of another commit belongs to its original run; an unmarked one whose version is on the feed is
    # a leftover of an interrupted Prepare or Restore, which only a maintainer can sort out.
    param(
        [Parameter(Mandatory)] $Context,
        [AllowNull()] $Release,
        [Parameter(Mandatory)] [bool] $PublicationStarted,
        [Parameter(Mandatory)] [string] $Action
    )
    if (-not $PublicationStarted -or -not $Release -or $Release.target_commitish -eq $Context.Commit) {
        return
    }
    if (Get-ReleaseAsset -Context $Context -Release $Release -Name (Get-ReleaseStateName).Marker) {
        throw ("Publication of $($Context.Tag) has already started from commit $($Release.target_commitish), but this run is " +
               "commit $($Context.Commit). Re-run the original pipeline run to finish $($Context.Tag), or bump the version.")
    }
    if ($Action -ne 'Restore' -and $Release.draft -and -not (Test-ReleaseSuperseded -Context $Context -Release $Release)) {
        throw ("The feed already holds version $($Context.Candidate.Text), but the only draft for $($Context.Tag) is unfinished (no " +
               "marker) and targets $($Release.target_commitish), not $($Context.Commit). A maintainer resolves this: identify the " +
               'commit whose package is on the feed, delete the unmarked draft on GitHub, and run -Action Restore with that ' +
               "commit's complete original artifacts (docs/RECOVERY.md, 'Missing draft').")
    }
}
