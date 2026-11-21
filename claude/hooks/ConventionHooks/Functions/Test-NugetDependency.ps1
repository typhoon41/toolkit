function Test-NugetDependency {
    # The nearest folder holding a .csproj is the project: its PackageReference, or a ProjectReference to
    # <Package>.csproj (the library built from source in the same repository). Directory.Build.props and
    # Directory.Packages.props in that folder or any above it count too, so central versions cover every project.
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [object] $Requirement
    )
    $package = [regex]::Escape($Requirement.Package)
    $packageReference = "(?is)<Package(?:Reference|Version)\b(?=[^>]*\b(?:Include|Update)\s*=\s*""$package"")(?<tag>[^>]*)>"
    $projectReference = "(?i)<ProjectReference\b[^>]*\bInclude\s*=\s*""(?:[^""]*[\\/])?$package\.csproj"""
    $projectFound = $false
    $folder = Split-Path -Parent ([IO.Path]::GetFullPath($Path))
    while ($folder) {
        $manifests = @(Get-ChildItem -LiteralPath $folder -File -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -in 'Directory.Build.props', 'Directory.Packages.props' -or (-not $projectFound -and $_.Extension -eq '.csproj')
            })
        $projectFound = $projectFound -or @($manifests | Where-Object Extension -eq '.csproj').Count -gt 0
        foreach ($manifest in $manifests) {
            $content = [string](Get-Content -LiteralPath $manifest.FullName -Raw)
            if ($content -match $projectReference) {
                return $true
            }
            foreach ($match in [regex]::Matches($content, $packageReference)) {
                $version = if ($match.Groups['tag'].Value -match '\bVersion\s*=\s*"(?<version>[^"]*)"') { $Matches.version } else { $null }
                if ($Requirement.AcceptsVersion($version)) {
                    return $true
                }
            }
        }
        $folder = Split-Path -Parent $folder
    }
    $false
}
