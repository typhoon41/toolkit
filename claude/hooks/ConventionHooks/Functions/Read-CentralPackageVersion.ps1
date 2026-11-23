function Read-CentralPackageVersion {
    # Package → version pinned by the nearest Directory.Packages.props at or above the project folder (central package
    # management). A pin is only a version, never a reference.
    param([Parameter(Mandatory)] [string] $Folder)
    $versions = @{}
    $current = [IO.Path]::GetFullPath($Folder)
    while ($current) {
        $central = Join-Path $current 'Directory.Packages.props'
        if (Test-Path -LiteralPath $central -PathType Leaf) {
            $document = Read-MsbuildXml -Path $central
            if ($document) {
                foreach ($node in $document.SelectNodes("//*[local-name()='PackageVersion']")) {
                    $versions[$node.GetAttribute('Include')] = Get-PackageReferenceVersion -Node $node
                }
            }
            return $versions
        }
        $current = Split-Path -Parent $current
    }
    $versions
}
