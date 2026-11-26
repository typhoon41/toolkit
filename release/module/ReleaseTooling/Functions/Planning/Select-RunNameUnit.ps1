function Select-RunNameUnit {
    # Without a configured or releasing unit, a release-branch build follows the unit released last, so its counter
    # continues that version (2.0.0.1, 2.0.0.2, ...). It looks at every release tag reachable from HEAD, not the
    # current version's tag: a bump whose release failed has none. Commit height orders tags; timestamps can tie.
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
            $heights = @(Get-ReleaseTag -Prefix $unit.tagPrefix -MergedInto HEAD | ForEach-Object {
                [int](Invoke-Git rev-list --count "refs/tags/$($_.Tag)")
            })
            if ($heights.Count -gt 0) {
                [pscustomobject]@{ Unit = $unit; Height = ($heights | Measure-Object -Maximum).Maximum }
            }
        })
        if ($released.Count -gt 0) {
            return ($released | Sort-Object -Property Height -Descending -Stable | Select-Object -First 1).Unit
        }
    }
    $Units[0]
}
