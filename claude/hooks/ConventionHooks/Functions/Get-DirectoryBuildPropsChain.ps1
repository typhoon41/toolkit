function Get-DirectoryBuildPropsChain {
    # The Directory.Build.props files MSBuild imports for a project folder, outermost first: the nearest one at or
    # above the folder, and further up only while the current file imports its parent through
    # $([MSBuild]::GetPathOfFileAbove('Directory.Build.props', ...)).
    param([Parameter(Mandatory)] [string] $Folder)
    $chain = @()
    $current = [IO.Path]::GetFullPath($Folder)
    while ($current) {
        $props = Join-Path $current 'Directory.Build.props'
        if (Test-Path -LiteralPath $props -PathType Leaf) {
            $chain = @($props) + $chain
            $document = Read-MsbuildXml -Path $props
            $parentImports = if ($document) {
                @($document.SelectNodes("//*[local-name()='Import']") |
                        Where-Object { $_.GetAttribute('Project') -match "GetPathOfFileAbove\(\s*'?Directory\.Build\.props" })
            }
            if (@($parentImports).Count -eq 0) {
                break
            }
        }
        $current = Split-Path -Parent $current
    }
    $chain
}
