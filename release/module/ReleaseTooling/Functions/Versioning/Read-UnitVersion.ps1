function Read-UnitVersion {
    <#
        Version of a nuget or npm unit in -Snapshot: @{ Text; PackageNames; SourceFiles }. Every project of
        a nuget unit must agree. Returns $null when the unit's files don't exist there (a new unit).
    #>
    param([Parameter(Mandatory)] $Unit, [Parameter(Mandatory)] $Snapshot)
    if ($Unit.Type -eq 'npm') {
        $npm = Read-NpmVersion -Snapshot $Snapshot -PackagePath $Unit.Package
        if (-not $npm) {
            return $null
        }
        return [pscustomobject]@{ Text = $npm.Text; PackageNames = @($npm.Name); SourceFiles = @($npm.SourceFile) }
    }

    $versions = @(foreach ($project in $Unit.Projects) {
        $version = Read-MSBuildVersion -Snapshot $Snapshot -ProjectPath $project
        if ($version) {
            [pscustomobject]@{ Project = $project; Text = $version.Text; SourceFile = $version.SourceFile }
        }
    })
    if ($versions.Count -eq 0) {
        return $null
    }
    $distinct = @($versions.Text | Select-Object -Unique)
    if ($distinct.Count -gt 1) {
        $detail = ($versions | ForEach-Object { "$($_.Project)=$($_.Text)" }) -join ', '
        throw "The projects of unit '$($Unit.Name)' must share one version, but have $detail."
    }
    [pscustomobject]@{
        Text         = $distinct[0]
        PackageNames = @()        # NuGet ids are read from the packed nuspec files

        SourceFiles  = @($versions.SourceFile | Select-Object -Unique)
    }
}
