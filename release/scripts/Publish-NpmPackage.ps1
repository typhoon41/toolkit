<#
.SYNOPSIS
    Publishes the tarball of every releasing npm unit of a plan. Safe to re-run.

.DESCRIPTION
    A version already on the registry with the same integrity is skipped (npm pack is reproducible); other bytes fail.
    NPM_TOKEN goes only to npmjs.org, Azure Artifacts or -TrustedFeedHost and is never written to disk; an .npmrc
    prepared by npmAuthenticate@0 works instead.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $PlanFile,
    [Parameter(Mandatory)] [string] $PackagesPath,
    [string] $Registry,
    [ValidateSet('', 'public', 'restricted')] [string] $Access = '',
    [string] $Unit,
    [AllowEmptyString()] [string] $TrustedFeedHost = ''      # extra npm hosts that may receive NPM_TOKEN
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force

$userConfiguration = $null
try {
    $plan = Get-Content -LiteralPath $PlanFile -Raw | ConvertFrom-Json
    $units = @($plan.units | Where-Object { $_.type -eq 'npm' -and $_.canRelease -and (-not $Unit -or $_.name -eq $Unit) })
    if ($units.Count -eq 0) {
        Write-ReleaseLog 'No npm unit releases in this build.'
        exit 0
    }

    foreach ($unitPlan in $units) {
        if ($Registry) {
            $unitPlan.npmRegistry = $Registry
        }
        $userConfiguration = Enable-NpmTokenAuthentication -Registry $unitPlan.npmRegistry -TrustedHost (ConvertTo-TrustedFeedHost $TrustedFeedHost)

        $files = Get-UnitPackageFile -UnitPlan $unitPlan -PackagesPath $PackagesPath -Require
        foreach ($file in $files) {
            $state = Get-NpmPackageState -File $file.FullName -Registry $unitPlan.npmRegistry
            if ($state.State -eq 'Published') {
                Write-ReleaseLog "$($state.Label) is already on the registry and identical to this build; skipping."
                continue
            }
            if ($state.State -eq 'Foreign') {
                throw "$($state.Label) is already on the registry ($($state.Detail)). Published versions are immutable: bump the version."
            }
            $distributionTag = if ($unitPlan.isPrerelease) { 'next' } else { 'latest' }
            $arguments = @('publish', $file.FullName, '--tag', $distributionTag, '--registry', $unitPlan.npmRegistry)
            if ($Access) {
                $arguments += @('--access', $Access)
            }
            Write-ReleaseLog "Publishing $($state.Label) to $($unitPlan.npmRegistry) as '$distributionTag'"
            Invoke-NpmCommand @arguments | ForEach-Object { Write-ReleaseLog $_ }
        }

        Disable-NpmTokenAuthentication $userConfiguration
        $userConfiguration = $null
    }
}
catch {
    Write-PipelineIssue -Type error -Message $_.Exception.Message
    exit 1
}
finally {
    Disable-NpmTokenAuthentication $userConfiguration
}
