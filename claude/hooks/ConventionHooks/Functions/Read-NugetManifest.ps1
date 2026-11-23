function Read-NugetManifest {
    # The packages the .NET projects of the file's project folder reference, by name only: a PackageReference Include
    # or a ProjectReference to <Package>.csproj (the library built from source) in the Directory.Build.props chain
    # MSBuild imports (Get-DirectoryBuildPropsChain) or in any .csproj of the folder. An Update or a central
    # PackageVersion alone adds nothing. Versions are not read: each package maps to an unknown version, which every
    # requirement accepts. Empty outside a .NET project.
    param([Parameter(Mandatory)] [string] $Path)
    $packages = @{}
    $projects = @(Find-MsbuildProject -Path $Path)
    if ($projects.Count -eq 0) {
        return $packages
    }
    $files = @(Get-DirectoryBuildPropsChain -Folder $projects[0].DirectoryName) + @($projects.FullName)
    foreach ($document in @($files | ForEach-Object { Read-MsbuildXml -Path $_ } | Where-Object { $_ })) {
        $names = @(
            $document.SelectNodes("//*[local-name()='PackageReference'][@Include]") | ForEach-Object { $_.GetAttribute('Include') }
            $document.SelectNodes("//*[local-name()='ProjectReference'][@Include]") |
                ForEach-Object { [IO.Path]::GetFileNameWithoutExtension(($_.GetAttribute('Include') -replace '\\', '/')) }
        )
        foreach ($name in $names | Where-Object { $_ }) {
            $packages[$name] = @('')
        }
    }
    $packages
}
