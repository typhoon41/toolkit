function Read-NugetManifest {
    # Package → version the file's .NET project references, read from the files MSBuild evaluates for it: the
    # Directory.Build.props chain it imports (Get-DirectoryBuildPropsChain), then the .csproj. A PackageReference or a
    # ProjectReference to <Package>.csproj (the library built from source, no version) is a reference. A reference
    # without a version takes it from the central pins (Read-CentralPackageVersion). Empty outside a .NET project.
    param([Parameter(Mandatory)] [string] $Path)
    $references = @{}
    $project = Find-MsbuildProject -Path $Path
    if (-not $project) {
        return $references
    }
    foreach ($file in @(Get-DirectoryBuildPropsChain -Folder $project.DirectoryName) + @($project.FullName)) {
        $document = Read-MsbuildXml -Path $file
        if (-not $document) {
            continue
        }
        foreach ($node in $document.SelectNodes("//*[local-name()='PackageReference']")) {
            $package = @($node.GetAttribute('Include'), $node.GetAttribute('Update')) | Where-Object { $_ } | Select-Object -First 1
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
    $centralVersions = Read-CentralPackageVersion -Folder $project.DirectoryName
    foreach ($package in @($references.Keys)) {
        if (-not $references[$package] -and $centralVersions.ContainsKey($package)) {
            $references[$package] = $centralVersions[$package]
        }
    }
    $references
}
