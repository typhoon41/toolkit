function Test-NpmDependency {
    # The nearest package.json above the file decides; peerDependencies count too (Angular libraries).
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [object] $Requirement
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
            foreach ($section in 'dependencies', 'devDependencies', 'peerDependencies') {
                if ($project[$section] -is [Collections.IDictionary] -and $project[$section].Contains($Requirement.Package)) {
                    return $Requirement.AcceptsVersion([string]$project[$section][$Requirement.Package])
                }
            }
            return $false
        }
        $folder = Split-Path -Parent $folder
    }
    $false
}
