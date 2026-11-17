function Get-UnitReleaseScope {
    <#
        Repository paths whose changes belong to a unit's release notes. An empty list means the whole
        repository. Explicit 'paths' in release.json win; a single-unit repository and a pipeline unit cover
        everything; otherwise the project/package directories plus the files the version came from.
    #>
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
