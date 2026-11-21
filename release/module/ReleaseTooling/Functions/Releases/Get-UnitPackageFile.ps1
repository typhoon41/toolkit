function Get-UnitPackageFile {
    param(
        [Parameter(Mandatory)] $UnitPlan,
        [Parameter(Mandatory)] [string] $PackagesPath,
        [switch] $Require
    )
    $directory = Join-Path $PackagesPath $UnitPlan.name
    $extensions = if ($UnitPlan.type -eq 'nuget') { @('.nupkg', '.snupkg') } else { @('.tgz') }
    $files = @(if (Test-Path -LiteralPath $directory) {
        Get-ChildItem -LiteralPath $directory -File -Recurse | Where-Object { $_.Extension -in $extensions } | Sort-Object Name
    })
    if ($Require -and $files.Count -eq 0) {
        throw "No packages for unit '$($UnitPlan.name)' in $directory."
    }
    foreach ($file in $files) {
        $version = if ($UnitPlan.type -eq 'nuget') { (Read-PackageNuspec $file.FullName).Version } else { (Read-NpmTarballManifest $file.FullName)['version'] }
        if ($version.ToLowerInvariant() -ne $UnitPlan.version) {
            throw "$($file.Name) has version '$version' but this release of '$($UnitPlan.name)' is $($UnitPlan.version)."
        }
    }
    , $files
}
