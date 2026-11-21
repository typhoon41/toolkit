function Get-RunName {
    param(
        [Parameter(Mandatory)] $UnitPlan,
        [Parameter(Mandatory)] [string] $BuildId,
        [Parameter(Mandatory)] [bool] $IsReleaseBranch,
        [Parameter(Mandatory)] [string] $Label
    )
    if ($UnitPlan.type -ne 'pipeline') {
        if ($UnitPlan.canRelease) {
            return "$($UnitPlan.version)+$([bigint]::Parse($BuildId))"
        }
        return $UnitPlan.packageVersion
    }
    if ($IsReleaseBranch -or $UnitPlan.version -match "[.-]$([regex]::Escape($Label))$") {
        return $UnitPlan.version      # a re-run of the job sees the already renamed build number
    }
    $separator = if ($UnitPlan.isPrerelease) { '.' } else { '-' }
    "$($UnitPlan.version)$separator$Label"
}
