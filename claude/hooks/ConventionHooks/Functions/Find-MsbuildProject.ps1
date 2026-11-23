function Find-MsbuildProject {
    # Every .csproj of the nearest folder at or above the file that holds any (sibling projects share the folder);
    # nothing outside a .NET project.
    param([Parameter(Mandatory)] [string] $Path)
    $folder = Split-Path -Parent ([IO.Path]::GetFullPath($Path))
    while ($folder) {
        $projects = @(Get-ChildItem -LiteralPath $folder -Filter '*.csproj' -File -ErrorAction SilentlyContinue)
        if ($projects.Count -gt 0) {
            return $projects
        }
        $folder = Split-Path -Parent $folder
    }
}
