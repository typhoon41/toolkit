function Get-PreviousReleaseReference {
    # Notes start after the previous release tag, or after the commit that set the previous version when the unit
    # has no tag yet; '' means the whole history. Plans written before previousCommit existed lack the property.
    param([Parameter(Mandatory)] $UnitPlan)
    if ($UnitPlan.previousTag) {
        return $UnitPlan.previousTag
    }
    $previousCommit = $UnitPlan.PSObject.Properties['previousCommit']
    if ($previousCommit -and $previousCommit.Value) {
        return $previousCommit.Value
    }
    ''
}
