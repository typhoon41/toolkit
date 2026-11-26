class ReleaseStateName {
    # Marker: publication started, kept until published. Superseded: abandoned, never publish.
    # Attempt: one asset per Prepare, i.e. per push attempt.
    static [string] $Marker = 'release-state.json'
    static [string] $Superseded = 'release-state.superseded.json'
    static [string] $AttemptPattern = '^release-attempt-\d{8}T\d{6}Z-[0-9a-f]{8}\.json$'

    static [string] Attempt([DateTimeOffset] $at) {
        return "release-attempt-$($at.ToString('yyyyMMddTHHmmssZ'))-$([Guid]::NewGuid().ToString('n').Substring(0, 8)).json"
    }

    static [bool] Includes([string] $name) {
        return $name -in [ReleaseStateName]::Marker, [ReleaseStateName]::Superseded -or $name -match [ReleaseStateName]::AttemptPattern
    }
}
