<#
.SYNOPSIS
    Pushes the packages of every releasing NuGet unit of a plan. Safe to re-run after a partial failure.

.DESCRIPTION
    A version already on the feed is compared entry by entry, signing aside: identical is skipped, different fails.
    Symbols are pushed with --skip-duplicate, so a failed symbol upload is retried. NUGET_API_KEY goes only to
    nuget.org or -TrustedFeedHost; Azure Artifacts gets 'az' after NuGetAuthenticate@1; other hosts are refused.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $PlanFile,
    [Parameter(Mandatory)] [string] $PackagesPath,
    [string] $Source,
    [string] $Unit,
    [AllowEmptyString()] [string] $TrustedFeedHost = ''
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force

function Invoke-NuGetPush([string] $File, [string] $Feed, [string] $ApiKey, [string[]] $ExtraArguments) {
    & dotnet nuget push $File --api-key $ApiKey --source $Feed @ExtraArguments
    if ($LASTEXITCODE -ne 0) {
        throw ("Push of $(Split-Path $File -Leaf) failed. If the feed reported a conflict, the package may already be " +
               'accepted but not yet indexed; re-run this job in a few minutes and it will be verified.')
    }
}

try {
    $plan = Get-Content -LiteralPath $PlanFile -Raw | ConvertFrom-Json
    $units = @($plan.units | Where-Object { $_.type -eq 'nuget' -and $_.canRelease -and (-not $Unit -or $_.name -eq $Unit) })
    if ($units.Count -eq 0) {
        Write-ReleaseLog 'No NuGet unit releases in this build.'
        exit 0
    }

    foreach ($unitPlan in $units) {
        if ($Source) {
            $unitPlan.nugetSource = $Source
        }
        $apiKey = Get-NuGetPushApiKey -Source $unitPlan.nugetSource -TrustedHost (ConvertTo-TrustedFeedHost $TrustedFeedHost)

        $files = Get-UnitPackageFile -UnitPlan $unitPlan -PackagesPath $PackagesPath -Require
        foreach ($file in $files) {
            $commit = (Read-PackageNuspec $file.FullName).Commit
            if ($commit -ne $plan.commit) {
                throw "$($file.Name) records commit '$commit', expected $($plan.commit). Was it packed by New-ReleasePackage.ps1?"
            }
        }

        foreach ($file in @($files | Where-Object Extension -eq '.nupkg')) {
            $state = Get-NuGetPackageState -File $file.FullName -Source $unitPlan.nugetSource -Commit $plan.commit
            if ($state.State -eq 'Published') {
                Write-ReleaseLog "$($state.Label) is already on the feed and identical to this build; skipping."
                continue
            }
            if ($state.State -eq 'Foreign') {
                throw ("$($state.Label) is already on the feed and is not this build ($($state.Detail)). Published versions are " +
                       'immutable: bump the version, or use "Rerun failed jobs" on the run that pushed it.')
            }
            Write-ReleaseLog "Pushing $($file.Name) to $($unitPlan.nugetSource)"
            Invoke-NuGetPush -File $file.FullName -Feed $unitPlan.nugetSource -ApiKey $apiKey -ExtraArguments @('--no-symbols')
        }
        foreach ($file in @($files | Where-Object Extension -eq '.snupkg')) {
            Write-ReleaseLog "Pushing symbols $($file.Name)"
            Invoke-NuGetPush -File $file.FullName -Feed $unitPlan.nugetSource -ApiKey $apiKey -ExtraArguments @('--skip-duplicate')
        }
    }
}
catch {
    Write-PipelineIssue -Type error -Message $_.Exception.Message
    exit 1
}
