function Get-FrozenReason {
    param([Parameter(Mandatory)] $Context)
    "Publication of $($Context.Tag) has already started (its package was pushed to the feed), so its assets are frozen. " +
    'Use "Rerun failed jobs" on the pipeline run that pushed it instead of a new run.'
}
