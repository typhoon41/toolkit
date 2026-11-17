<#
.SYNOPSIS
    Packs every NuGet and npm unit of a release plan with its planned version into <OutDirectory>/<unit>/.

.DESCRIPTION
    NuGet: dotnet pack per project with -p:Version/PackageVersion, RepositoryUrl and RepositoryCommit, so
    the publish step can prove which commit a package came from.
    npm:   npm version (working copy only, restored afterwards) + npm pack.

    When -NotesDirectory holds <unit>.txt / <unit>.md (New-ReleaseNotes.ps1), a releasing unit carries
    its notes: NuGet as PackageReleaseNotes, npm as RELEASE-NOTES.md in the tarball. Without notes the
    packages are built as they are. Pipeline (application) units are skipped.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $PlanFile,
    [Parameter(Mandatory)] [string] $OutDirectory,
    [string] $NotesDirectory,
    [string] $RepositoryUrl,
    [string] $RepositoryRoot = '.',
    [string] $Configuration = 'Release',
    [string] $Unit
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force

$here = (Get-Location).Path
$planPath = [IO.Path]::GetFullPath($PlanFile, $here)
$outPath = [IO.Path]::GetFullPath($OutDirectory, $here)
$notesPath = if ($NotesDirectory) { [IO.Path]::GetFullPath($NotesDirectory, $here) } else { '' }

Push-Location -LiteralPath $RepositoryRoot
try {
    $plan = Get-Content -LiteralPath $planPath -Raw | ConvertFrom-Json
    if ((Invoke-Git rev-parse HEAD) -ne $plan.commit) {
        throw "The plan was made for commit $($plan.commit), but the working copy is at $(Invoke-Git rev-parse HEAD)."
    }
    if (-not $RepositoryUrl) {
        $RepositoryUrl = "https://github.com/$(Get-GitHubRepositoryName)"
    }

    $units = @($plan.units | Where-Object { $_.type -in 'nuget', 'npm' -and (-not $Unit -or $_.name -eq $Unit) })
    foreach ($unitPlan in $units) {
        $destination = Join-Path $outPath $unitPlan.name
        $extension = if ($unitPlan.type -eq 'nuget') { 'txt' } else { 'md' }
        $notesFile = if ($notesPath -and $unitPlan.canRelease) { Join-Path $notesPath "$($unitPlan.name).$extension" } else { '' }
        if ($notesFile -and -not (Test-Path -LiteralPath $notesFile)) {
            $notesFile = ''
        }
        $withNotes = if ($notesFile) { 'with release notes' } else { 'without release notes' }
        Write-ReleaseLog "Packing $($unitPlan.name) $($unitPlan.packageVersion) $withNotes"

        if ($unitPlan.type -eq 'nuget') {
            Invoke-NuGetPack -UnitPlan $unitPlan -Commit $plan.commit -RepositoryUrl $RepositoryUrl -OutDirectory $destination `
                -NotesFile $notesFile -Configuration $Configuration
        }
        else {
            $tarball = Invoke-NpmPack -UnitPlan $unitPlan -OutDirectory $destination -NotesFile $notesFile
            Write-ReleaseLog "Packed $tarball"
        }
    }
    if ($units.Count -eq 0) {
        Write-ReleaseLog 'The plan has no NuGet or npm units; nothing to pack.'
    }
}
catch {
    Write-PipelineIssue -Type error -Message $_.Exception.Message
    exit 1
}
finally {
    Pop-Location
}
