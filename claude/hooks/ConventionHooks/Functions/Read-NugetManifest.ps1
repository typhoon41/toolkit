function Read-NugetManifest {
    # Package → version the file's .NET project references, read from the files MSBuild evaluates for it: the
    # Directory.Build.props chain it imports (Get-DirectoryBuildPropsChain, outermost first), then every .csproj of the
    # project folder. A PackageReference Include or a ProjectReference to <Package>.csproj (the library built from
    # source, no version) is a reference; a later Include of the same package wins, so the nearer file's version
    # counts. Items are read in MSBuild's evaluation order (file by file, top to bottom), so a PackageReference Update
    # only changes the version of a package included earlier; an Update before its Include changes nothing. A
    # reference without a version takes it from the central pins (Read-CentralPackageVersion). Empty outside a .NET
    # project.
    param([Parameter(Mandatory)] [string] $Path)
    $references = @{}
    $projects = @(Find-MsbuildProject -Path $Path)
    if ($projects.Count -eq 0) {
        return $references
    }
    $folder = $projects[0].DirectoryName
    $documents = @(@(Get-DirectoryBuildPropsChain -Folder $folder) + @($projects.FullName) |
            ForEach-Object { Read-MsbuildXml -Path $_ } | Where-Object { $_ })
    foreach ($document in $documents) {
        foreach ($node in $document.SelectNodes("//*[local-name()='PackageReference']")) {
            $included = $node.GetAttribute('Include')
            $updated = $node.GetAttribute('Update')
            $version = Get-PackageReferenceVersion -Node $node
            if ($included) {
                $references[$included] = $version
            }
            elseif ($updated -and $version -and $references.ContainsKey($updated)) {
                $references[$updated] = $version
            }
        }
        foreach ($node in $document.SelectNodes("//*[local-name()='ProjectReference']")) {
            $name = [IO.Path]::GetFileNameWithoutExtension(($node.GetAttribute('Include') -replace '\\', '/'))
            if ($name -and -not $references.ContainsKey($name)) {
                $references[$name] = ''
            }
        }
    }
    $centralVersions = Read-CentralPackageVersion -Folder $folder
    foreach ($package in @($references.Keys)) {
        if (-not $references[$package] -and $centralVersions.ContainsKey($package)) {
            $references[$package] = $centralVersions[$package]
        }
    }
    $references
}
