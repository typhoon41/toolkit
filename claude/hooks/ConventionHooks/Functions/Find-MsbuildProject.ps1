function Find-MsbuildProject {
    # Every .csproj of the nearest folder at or above the file that holds any; nothing outside a .NET project. All
    # siblings count: SDK-style projects compile every .cs file under their folder by default, so each builds the file.
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
