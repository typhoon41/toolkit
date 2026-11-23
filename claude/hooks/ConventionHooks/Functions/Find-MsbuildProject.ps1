function Find-MsbuildProject {
    # The .csproj of the nearest folder at or above the file that holds one; nothing outside a .NET project.
    param([Parameter(Mandatory)] [string] $Path)
    $folder = Split-Path -Parent ([IO.Path]::GetFullPath($Path))
    while ($folder) {
        $project = Get-ChildItem -LiteralPath $folder -Filter '*.csproj' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($project) {
            return $project
        }
        $folder = Split-Path -Parent $folder
    }
}
