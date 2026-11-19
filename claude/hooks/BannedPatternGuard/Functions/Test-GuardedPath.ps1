function Test-GuardedPath {
    # False for generated or third-party code: dependencies, build output and EF Core migrations.
    param([Parameter(Mandatory)] [string] $Path)
    $Path -notmatch '(?i)(?:^|[\\/])(?:node_modules|bin|obj|dist|\.angular|Migrations)[\\/]'
}
