function New-GitHubReleaseContext {
    param(
        [Parameter(Mandatory)] $Client,
        [Parameter(Mandatory)] $UnitPlan,
        [Parameter(Mandatory)] [ValidatePattern('^[0-9a-f]{40}$')] [string] $Commit,
        [AllowEmptyCollection()] [IO.FileInfo[]] $Files = @()
    )
    $candidate = ConvertTo-ReleaseVersion $UnitPlan.version
    if (-not $candidate) {
        throw "Version '$($UnitPlan.version)' is invalid: $(Get-VersionProblem $UnitPlan.version)."
    }
    $packageIds = @(foreach ($file in @($Files)) {
        if ($file.Extension -eq '.nupkg') {
            (Read-PackageNuspec $file.FullName).Id
        }
        elseif ($file.Extension -eq '.tgz') {
            (Read-NpmTarballManifest $file.FullName)['name']
        }
    }) | Select-Object -Unique

    [pscustomobject]@{
        Client     = $Client
        Unit       = $UnitPlan
        Candidate  = $candidate
        Tag        = "$($UnitPlan.tagPrefix)$($candidate.Text)"
        Prefix     = $UnitPlan.tagPrefix
        Commit     = $Commit
        Files      = @($Files)
        PackageIds = @($packageIds)
    }
}
