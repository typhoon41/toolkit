function Read-MsbuildProjectReference {
    # Package → version one project references, from the XML of the files MSBuild evaluates for it, in evaluation order
    # (its Directory.Build.props chain, outermost first, then the project file), top to bottom. A PackageReference
    # Include or a ProjectReference to <Package>.csproj (the library built from source, no version) is a reference; a
    # later Include of the same package wins, so the nearer file's version counts. A PackageReference Update only
    # changes the version of a package included earlier; an Update before its Include changes nothing.
    param([AllowEmptyCollection()] [Xml.XmlDocument[]] $Document = @())
    $references = @{}
    foreach ($file in $Document) {
        foreach ($node in $file.SelectNodes("//*[local-name()='PackageReference']")) {
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
        foreach ($node in $file.SelectNodes("//*[local-name()='ProjectReference']")) {
            $name = [IO.Path]::GetFileNameWithoutExtension(($node.GetAttribute('Include') -replace '\\', '/'))
            if ($name -and -not $references.ContainsKey($name)) {
                $references[$name] = ''
            }
        }
    }
    $references
}
