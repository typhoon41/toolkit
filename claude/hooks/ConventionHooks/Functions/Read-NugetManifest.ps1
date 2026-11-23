function Read-NugetManifest {
    # Package → every version the .NET projects of the file's project folder reference (sibling .csproj files share
    # the folder). MSBuild evaluates each project on its own, so each is read separately with the Directory.Build.props
    # chain it imports (Read-MsbuildProjectReference); a reference without a version takes it from the central pins
    # (Read-CentralPackageVersion). Empty outside a .NET project.
    param([Parameter(Mandatory)] [string] $Path)
    $versions = @{}
    $projects = @(Find-MsbuildProject -Path $Path)
    if ($projects.Count -eq 0) {
        return $versions
    }
    $folder = $projects[0].DirectoryName
    $props = @(Get-DirectoryBuildPropsChain -Folder $folder | ForEach-Object { Read-MsbuildXml -Path $_ } | Where-Object { $_ })
    $centralVersions = Read-CentralPackageVersion -Folder $folder
    foreach ($project in $projects) {
        $document = Read-MsbuildXml -Path $project.FullName
        if (-not $document) {
            continue
        }
        $references = Read-MsbuildProjectReference -Document (@($props) + @($document))
        foreach ($package in $references.Keys) {
            $version = $references[$package]
            if (-not $version -and $centralVersions.ContainsKey($package)) {
                $version = $centralVersions[$package]
            }
            $versions[$package] = @(if ($versions.ContainsKey($package)) { $versions[$package] }) + @($version)
        }
    }
    $versions
}
