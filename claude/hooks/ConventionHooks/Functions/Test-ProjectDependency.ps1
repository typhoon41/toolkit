function Test-ProjectDependency {
    # Whether the project a file belongs to - the nearest package.json at or above the file's folder - lists the
    # package in dependencies or devDependencies. False without a package.json or when it cannot be read.
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Package
    )
    $folder = Split-Path -Parent ([IO.Path]::GetFullPath($Path))
    while ($folder) {
        $manifest = Join-Path $folder 'package.json'
        if (Test-Path -LiteralPath $manifest -PathType Leaf) {
            try {
                $project = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json -AsHashtable
            }
            catch {
                return $false
            }
            foreach ($section in 'dependencies', 'devDependencies') {
                if ($project[$section] -is [Collections.IDictionary] -and $project[$section].Contains($Package)) {
                    return $true
                }
            }
            return $false
        }
        $folder = Split-Path -Parent $folder
    }
    $false
}
