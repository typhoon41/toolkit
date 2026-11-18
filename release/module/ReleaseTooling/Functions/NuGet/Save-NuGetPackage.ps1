function Save-NuGetPackage {
    # Downloads <id> <version> from the flat container to a temporary file and returns its path.
    param(
        [Parameter(Mandatory)] [string] $FlatContainer,
        [Parameter(Mandatory)] [string] $Id,
        [Parameter(Mandatory)] [string] $Version,
        [hashtable] $Headers = @{}
    )
    $lowercaseId = $Id.ToLowerInvariant()
    $lowercaseVersion = $Version.ToLowerInvariant()
    $file = Join-Path ([IO.Path]::GetTempPath()) "$([Guid]::NewGuid().ToString('n'))-$lowercaseId.$lowercaseVersion.nupkg"
    Invoke-WebRequest -Uri "$FlatContainer$lowercaseId/$lowercaseVersion/$lowercaseId.$lowercaseVersion.nupkg" -Headers $Headers -OutFile $file
    $file
}
