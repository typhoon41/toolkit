function Get-ReleaseStateName {
    # Marker: publication started, kept until published. Superseded: abandoned, never publish.
    # Attempt: one asset per Prepare, i.e. per push attempt.
    [pscustomobject]@{
        Marker         = 'release-state.json'
        Superseded     = 'release-state.superseded.json'
        AttemptPattern = '^release-attempt-\d{8}T\d{6}Z-[0-9a-f]{8}\.json$'
    }
}
