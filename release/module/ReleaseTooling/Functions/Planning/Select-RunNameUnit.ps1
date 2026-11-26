function Select-RunNameUnit {
    # Without a configured or releasing unit, a release-branch build follows the unit released last, so its counter
    # continues that version (2.0.0.1, 2.0.0.2, ...). Commit height orders the tags: timestamps can tie or lie.
    param(
        [Parameter(Mandatory)] [object[]] $Units,
        [AllowEmptyString()] [string] $ConfiguredName,
        [Parameter(Mandatory)] [bool] $IsReleaseBranch
    )
    $configured = @($Units | Where-Object { $ConfiguredName -and $_.name -eq $ConfiguredName })
    if ($configured.Count -gt 0) {
        return $configured[0]
    }
    $releasing = @($Units | Where-Object { $_.canRelease })
    if ($releasing.Count -gt 0) {
        return $releasing[0]
    }
    if ($IsReleaseBranch) {
        $released = @(foreach ($unit in $Units) {
            $commit = Get-TagTargetCommit $unit.tag
            if ($commit) {
                [pscustomobject]@{ Unit = $unit; Height = [int](Invoke-Git rev-list --count $commit) }
            }
        })
        if ($released.Count -gt 0) {
            return ($released | Sort-Object -Property Height -Descending -Stable | Select-Object -First 1).Unit
        }
    }
    $Units[0]
}
