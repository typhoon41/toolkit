function Get-RunName {
    # CountsRuns: jobs/run-counter.yml appends a counter that restarts with every version (1.3.0.1, 1.3.0.2, ...).
    param(
        [Parameter(Mandatory)] $UnitPlan,
        [Parameter(Mandatory)] [bool] $IsReleaseBranch,
        [Parameter(Mandatory)] [string] $Label
    )
    if ($UnitPlan.type -ne 'pipeline') {
        if ($UnitPlan.canRelease) {
            return [pscustomobject]@{ Text = $UnitPlan.version; CountsRuns = $true }
        }
        return [pscustomobject]@{ Text = $UnitPlan.packageVersion; CountsRuns = $false }
    }
    if ($IsReleaseBranch -or $UnitPlan.version -match "[.-]$([regex]::Escape($Label))$") {
        # a re-run of the job sees the already renamed build number
        return [pscustomobject]@{ Text = $UnitPlan.version; CountsRuns = $false }
    }
    $separator = if ($UnitPlan.isPrerelease) { '.' } else { '-' }
    [pscustomobject]@{ Text = "$($UnitPlan.version)$separator$Label"; CountsRuns = $false }
}
