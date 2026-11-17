function Invoke-NuGetPack {
    <#
        Packs every project of a nuget unit with the plan's package version into -OutDirectory, recording
        the repository and commit in the nuspec. With -NotesFile the text becomes PackageReleaseNotes.
    #>
    param(
        [Parameter(Mandatory)] $UnitPlan,
        [Parameter(Mandatory)] [ValidatePattern('^[0-9a-f]{40}$')] [string] $Commit,
        [Parameter(Mandatory)] [string] $RepositoryUrl,
        [Parameter(Mandatory)] [string] $OutDirectory,
        [string] $NotesFile,
        [string] $Configuration = 'Release',
        [string[]] $AdditionalArguments = @()
    )
    New-Item -ItemType Directory -Force -Path $OutDirectory | Out-Null
    $arguments = @(
        '-c', $Configuration, '-o', $OutDirectory,
        "-p:Version=$($UnitPlan.packageVersion)", "-p:PackageVersion=$($UnitPlan.packageVersion)",
        '-p:ContinuousIntegrationBuild=true', '-p:RepositoryType=git',
        "-p:RepositoryUrl=$RepositoryUrl", "-p:RepositoryCommit=$Commit"
    )
    if ($NotesFile) {
        $targets = New-ReleaseNotesTargetsFile -NotesFile $NotesFile -OutFile (Join-Path ([IO.Path]::GetTempPath()) "release-notes-$($UnitPlan.name).targets")
        $arguments += "-p:CustomAfterMicrosoftCommonTargets=$targets"
    }
    foreach ($project in $UnitPlan.projects) {
        Write-ReleaseLog "dotnet pack $project ($($UnitPlan.packageVersion))"
        & dotnet pack $project @arguments @AdditionalArguments
        if ($LASTEXITCODE -ne 0) {
            throw "dotnet pack $project failed (exit code $LASTEXITCODE)."
        }
    }
}
