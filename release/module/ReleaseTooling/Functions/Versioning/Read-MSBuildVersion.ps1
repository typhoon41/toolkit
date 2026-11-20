function Read-MSBuildVersion {
    param([Parameter(Mandatory)] $Snapshot, [Parameter(Mandatory)] [string] $ProjectPath)
    $projectText = $Snapshot.ReadText($ProjectPath)
    if ($null -eq $projectText) {
        return $null
    }
    $version = Get-MSBuildPropertyValue -XmlText $projectText -Name 'Version' -FilePath $ProjectPath
    if ($version) {
        return [pscustomobject]@{ Text = $version; SourceFile = $ProjectPath }
    }

    $directory = Split-RepositoryPath $ProjectPath
    while ($true) {
        $propsPath = if ($directory) { "$directory/Directory.Build.props" } else { 'Directory.Build.props' }
        $propsText = $Snapshot.ReadText($propsPath)
        if ($null -ne $propsText) {
            $version = Get-MSBuildPropertyValue -XmlText $propsText -Name 'Version' -FilePath $propsPath
            if ($version) {
                return [pscustomobject]@{ Text = $version; SourceFile = $propsPath }
            }
            if ($propsText -notmatch "GetPathOfFileAbove\(\s*'?Directory\.Build\.props") {
                break      # MSBuild only imports the nearest props file unless it chains to its parent
            }
        }
        if (-not $directory) {
            break
        }
        $directory = Split-RepositoryPath $directory
    }
    throw "$ProjectPath has no <Version>, and no Directory.Build.props above it sets one. Add <Version>1.0.0</Version> to either."
}
