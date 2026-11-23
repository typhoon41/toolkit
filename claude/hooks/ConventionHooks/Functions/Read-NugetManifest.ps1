function Read-NugetManifest {
    # Package → version the file's .NET project references, read from the files MSBuild evaluates for it: the
    # Directory.Build.props chain it imports (Get-DirectoryBuildPropsChain), then the .csproj. A PackageReference or a
    # PackageReference Include or a ProjectReference to <Package>.csproj (the library built from source, no version)
    # is a reference; a PackageReference Update only changes the version of a package already included, as in
    # MSBuild. A reference without a version takes it from the central pins (Read-CentralPackageVersion). Empty
    # outside a .NET project.
    param([Parameter(Mandatory)] [string] $Path)
    $references = @{}
    $project = Find-MsbuildProject -Path $Path
    if (-not $project) {
        return $references
    }
    $documents = @(@(Get-DirectoryBuildPropsChain -Folder $project.DirectoryName) + @($project.FullName) |
            ForEach-Object { Read-MsbuildXml -Path $_ } | Where-Object { $_ })
    foreach ($document in $documents) {
        foreach ($node in $document.SelectNodes("//*[local-name()='PackageReference'][@Include]")) {
            $package = $node.GetAttribute('Include')
            if ($package -and -not $references.ContainsKey($package)) {
                $references[$package] = Get-PackageReferenceVersion -Node $node
            }
        }
        foreach ($node in $document.SelectNodes("//*[local-name()='ProjectReference']")) {
            $name = [IO.Path]::GetFileNameWithoutExtension(($node.GetAttribute('Include') -replace '\\', '/'))
            if ($name -and -not $references.ContainsKey($name)) {
                $references[$name] = ''
            }
        }
    }
    foreach ($document in $documents) {
        foreach ($node in $document.SelectNodes("//*[local-name()='PackageReference'][@Update]")) {
            $package = $node.GetAttribute('Update')
            $version = Get-PackageReferenceVersion -Node $node
            if ($references.ContainsKey($package) -and $version) {
                $references[$package] = $version
            }
        }
    }
    $centralVersions = Read-CentralPackageVersion -Folder $project.DirectoryName
    foreach ($package in @($references.Keys)) {
        if (-not $references[$package] -and $centralVersions.ContainsKey($package)) {
            $references[$package] = $centralVersions[$package]
        }
    }
    $references
}
