<#
    Folders the hooks never check: dependencies, build output and EF Core migrations are changed through their source
    and regenerated. A project adds or removes folders in .claude/conventions.json (excludedFolders.add / .remove).
    Generated files (*.Designer.cs, *.g.cs, *.generated.*) are always skipped (Test-GuardedPath).
#>
@{
    ExcludedFolders = @('node_modules', 'bin', 'obj', 'dist', '.angular', 'Migrations')
}
