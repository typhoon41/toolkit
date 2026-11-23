function Read-NpmManifest {
    # Package → declared version from the nearest package.json above the file (dependencies, devDependencies,
    # optionalDependencies and peerDependencies, which Angular libraries use). Empty without a readable manifest.
    param([Parameter(Mandatory)] [string] $Path)
    $packages = @{}
    $folder = Split-Path -Parent ([IO.Path]::GetFullPath($Path))
    while ($folder) {
        $manifest = Join-Path $folder 'package.json'
        if (Test-Path -LiteralPath $manifest -PathType Leaf) {
            try {
                $project = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json -AsHashtable
            }
            catch {
                return $packages
            }
            foreach ($section in 'dependencies', 'devDependencies', 'optionalDependencies', 'peerDependencies') {
                if ($project[$section] -is [Collections.IDictionary]) {
                    foreach ($package in $project[$section].Keys) {
                        $packages[$package] = [string]$project[$section][$package]
                    }
                }
            }
            return $packages
        }
        $folder = Split-Path -Parent $folder
    }
    $packages
}
