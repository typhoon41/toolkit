function Get-ReleaseStateName {
    <#
        Names of the state assets on a draft release:
          Marker      publication started; permanent until published
          Superseded  abandoned by a maintainer; never publish
          Attempt     pattern of one asset per Prepare, i.e. per push attempt
    #>
    [pscustomobject]@{
        Marker         = 'release-state.json'
        Superseded     = 'release-state.superseded.json'
        AttemptPattern = '^release-attempt-\d{8}T\d{6}Z-[0-9a-f]{8}\.json$'
    }
}
