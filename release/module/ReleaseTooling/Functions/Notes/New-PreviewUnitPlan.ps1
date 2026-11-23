function New-PreviewUnitPlan {
    param(
        [Parameter(Mandatory)] [string] $RepositoryRoot,
        [Parameter(Mandatory)] [string] $UnitName,
        [Parameter(Mandatory)] [string] $Version,
        [string] $ConfigurationPath = 'release.json'
    )
    $configuration = Read-ReleaseConfiguration -RepositoryRoot $RepositoryRoot -Path $ConfigurationPath
    $unit = $configuration.Units | Where-Object Name -eq $UnitName
    if (-not $unit) {
        throw "release.json has no unit '$UnitName'. Units: $($configuration.Units.Name -join ', ')."
    }
    $candidate = ConvertTo-ReleaseVersion $Version
    if (-not $candidate) {
        throw "Version '$Version' is invalid: $(Get-VersionProblem $Version)."
    }
    $sourceFiles = if ($unit.Type -eq 'pipeline') { @() }
                   else { (Read-UnitVersion -Unit $unit -Snapshot (New-RepositorySnapshot -RepositoryRoot $RepositoryRoot)).SourceFiles }
    $previous = Get-PreviousReleaseTag -Prefix $unit.TagPrefix -Version $candidate
    $previousCommit = if ($previous) { '' }
                      else { Get-PreviousVersionCommit -Unit $unit -Version $candidate.Text -SourceFiles @($sourceFiles | Where-Object { $_ }) -RepositoryRoot $RepositoryRoot }
    [pscustomobject]@{
        name        = $unit.Name
        type        = $unit.Type
        version     = $candidate.Text
        tag         = "$($unit.TagPrefix)$($candidate.Text)"
        previousTag = if ($previous) { $previous.Tag } else { '' }
        previousCommit = $previousCommit
        paths       = Get-UnitReleaseScope -Unit $unit -VersionSourceFiles $sourceFiles
        canRelease  = $true
    }
}
