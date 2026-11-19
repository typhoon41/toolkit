function Test-GuardedPath {
    # False for code nobody writes by hand: dependencies, build output, EF Core migrations and generated files
    # (*.Designer.cs, *.g.cs, *.generated.*), which are changed through their source and regenerated.
    param([Parameter(Mandatory)] [string] $Path)
    $Path -notmatch '(?i)(?:^|[\\/])(?:node_modules|bin|obj|dist|\.angular|Migrations)[\\/]' -and
        $Path -notmatch '(?i)\.(?:designer|g|generated)\.[a-z]+$'
}
