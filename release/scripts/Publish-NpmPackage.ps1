<#
.SYNOPSIS
    Publishes the tarball of every releasing npm unit of a plan. Idempotent: safe to re-run.

.DESCRIPTION
    For each unit's .tgz in <PackagesPath>/<unit>/:
      - its package.json must carry the plan's version;
      - if the version is already on the registry with the same integrity (npm pack is reproducible),
        it was published by an earlier attempt of this build and is skipped; with different bytes the
        step fails (the version is taken);
      - otherwise it is published with dist-tag 'latest', or 'next' for a prerelease.

    Authentication: NPM_TOKEN environment variable (a temporary user config references it; the token is
    never written to disk), or an .npmrc prepared earlier, e.g. by npmAuthenticate@0 for Azure Artifacts.
    The registry is the unit's npmRegistry unless -Registry is given.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $PlanFile,
    [Parameter(Mandatory)] [string] $PackagesPath,
    [string] $Registry,
    [ValidateSet('', 'public', 'restricted')] [string] $Access = '',
    [string] $Unit
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
        $userConfiguration = Enable-NpmTokenAuthentication -Registry $unitPlan.npmRegistry

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
