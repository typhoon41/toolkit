function Select-RunNameUnit {
    # Without a configured or releasing unit, a release-branch build follows the unit released last, so its counter
    # continues that version (2.0.0.1, 2.0.0.2, ...). It looks at every release tag reachable from HEAD, not the
    # current version's tag: a bump whose release failed has none. History order ranks tags; timestamps can tie.
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
        $recency = Get-TagRecency
        $released = @(foreach ($unit in $Units) {
            $positions = @(Get-ReleaseTag -Prefix $unit.tagPrefix | Where-Object { $recency.ContainsKey($_.Tag) } |
                ForEach-Object { $recency[$_.Tag] })
            if ($positions.Count -gt 0) {
                [pscustomobject]@{ Unit = $unit; Position = ($positions | Measure-Object -Minimum).Minimum }
            }
        })
        if ($released.Count -gt 0) {
            return ($released | Sort-Object -Property Position -Stable | Select-Object -First 1).Unit
        }
    }
    $Units[0]
}
