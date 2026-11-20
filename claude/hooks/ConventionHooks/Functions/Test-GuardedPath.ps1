function Test-GuardedPath {
    # Generated and vendored code (dependencies, build output, EF Core migrations, *.Designer.cs, *.g.cs,
    # *.generated.*) is changed through its source and regenerated.
    param([Parameter(Mandatory)] [string] $Path)
    $Path -notmatch '(?i)(?:^|[\\/])(?:node_modules|bin|obj|dist|\.angular|Migrations)[\\/]' -and
        $Path -notmatch '(?i)\.(?:designer|g|generated)\.[a-z]+$'
}
