function Get-UnitReleaseScope {
    param([Parameter(Mandatory)] $Unit, [AllowEmptyCollection()] [string[]] $VersionSourceFiles = @())
    if ($null -ne $Unit.Paths) {
        return , @($Unit.Paths | Where-Object { $_ } | Select-Object -Unique)
    }
    if ($Unit.IsOnlyUnit -or $Unit.Type -eq 'pipeline') {
        return , @()
    }
    $owned = if ($Unit.Type -eq 'npm') { @($Unit.Package) } else { @($Unit.Projects) }
    $directories = @($owned | ForEach-Object { Split-RepositoryPath $_ })
    if ($directories -contains '') {
        return , @()        # a project at the root owns the whole repository
    }
    , @(@($directories) + @($VersionSourceFiles) | Where-Object { $_ } | Select-Object -Unique)
}
