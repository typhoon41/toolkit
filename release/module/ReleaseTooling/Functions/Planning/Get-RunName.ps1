function Get-RunName {
    <#
        Name of the Azure Pipelines run, from the unit that names it:
          package unit releasing    1.3.0+4711
          package unit otherwise    its package version (1.3.1-ci.4711, 1.3.1-calendar-fixes.4711)
          pipeline unit             its version on the release branch, <version>-<branch words> elsewhere
    #>
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
