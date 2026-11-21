function Read-NugetManifest {
    # Package → version the file's .NET project references: PackageReference in the nearest .csproj and in every
    # Directory.Build.props above it, plus a ProjectReference to <Package>.csproj (the library built from source, no
    # version). A reference without an inline version takes it from the nearest Directory.Packages.props; a central
    # PackageVersion alone is only a version pin, never a reference. Empty outside a .NET project.
    param([Parameter(Mandatory)] [string] $Path)
    $references = @{}
    $centralVersions = $null
    $projectFound = $false
    $folder = Split-Path -Parent ([IO.Path]::GetFullPath($Path))
    while ($folder) {
        $files = @(Get-ChildItem -LiteralPath $folder -File -ErrorAction SilentlyContinue)
        $projects = @($files | Where-Object { -not $projectFound -and $_.Extension -eq '.csproj' })
        $projectFound = $projectFound -or $projects.Count -gt 0
        foreach ($file in @($projects) + @($files | Where-Object Name -eq 'Directory.Build.props')) {
            $document = Read-MsbuildXml -Path $file.FullName
            if (-not $document) {
                continue
            }
            foreach ($node in $document.SelectNodes("//*[local-name()='PackageReference']")) {
                $package = @($node.GetAttribute('Include'), $node.GetAttribute('Update')) | Where-Object { $_ } | Select-Object -First 1
                if ($package -and -not $references.ContainsKey($package)) {
                    $version = $node.GetAttribute('Version')
                    $versionElement = $node.SelectSingleNode("*[local-name()='Version']")
                    if (-not $version -and $versionElement) {
                        $version = $versionElement.InnerText
                    }
                    $references[$package] = $version
                }
            }
            foreach ($node in $document.SelectNodes("//*[local-name()='ProjectReference']")) {
                $name = [IO.Path]::GetFileNameWithoutExtension(($node.GetAttribute('Include') -replace '\\', '/'))
                if ($name -and -not $references.ContainsKey($name)) {
                    $references[$name] = ''
                }
            }
        }
        $central = $files | Where-Object Name -eq 'Directory.Packages.props' | Select-Object -First 1
        if ($null -eq $centralVersions -and $central) {
            $centralVersions = @{}
            $document = Read-MsbuildXml -Path $central.FullName
            if ($document) {
                foreach ($node in $document.SelectNodes("//*[local-name()='PackageVersion']")) {
                    $centralVersions[$node.GetAttribute('Include')] = $node.GetAttribute('Version')
                }
            }
        }
        $folder = Split-Path -Parent $folder
    }
    foreach ($package in @($references.Keys)) {
        if (-not $references[$package] -and $centralVersions -and $centralVersions.ContainsKey($package)) {
            $references[$package] = $centralVersions[$package]
        }
    }
    $references
}
