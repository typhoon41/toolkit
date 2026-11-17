function Save-NuGetPackage {
    # Downloads <id> <version> from the flat container to a temporary file and returns its path.
    param(
        [Parameter(Mandatory)] [string] $FlatContainer,
        [Parameter(Mandatory)] [string] $Id,
        [Parameter(Mandatory)] [string] $Version,
        [hashtable] $Headers = @{}
    )
    $id = $Id.ToLowerInvariant()
    $version = $Version.ToLowerInvariant()
    $file = Join-Path ([IO.Path]::GetTempPath()) "$([Guid]::NewGuid().ToString('n'))-$id.$version.nupkg"
    Invoke-WebRequest -Uri "$FlatContainer$id/$version/$id.$version.nupkg" -Headers $Headers -OutFile $file
    $file
}
