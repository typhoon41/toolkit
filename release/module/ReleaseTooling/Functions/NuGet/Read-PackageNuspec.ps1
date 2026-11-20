function Read-PackageNuspec {
    param([Parameter(Mandatory)] [string] $Path)
    $archive = [IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $entry = $archive.Entries | Where-Object { $_.FullName -notmatch '/' -and $_.Name -like '*.nuspec' } | Select-Object -First 1
        if (-not $entry) {
            throw "No nuspec found in $Path"
        }
        $reader = [IO.StreamReader]::new($entry.Open())
        try {
            $nuspec = [xml]$reader.ReadToEnd()
        }
        finally {
            $reader.Dispose()
        }
    }
    finally {
        $archive.Dispose()
    }

    $metadata = $nuspec.SelectSingleNode("/*[local-name()='package']/*[local-name()='metadata']")
    if (-not $metadata) {
        throw "The nuspec in $Path has no metadata element"
    }
    $repository = $metadata.SelectSingleNode("*[local-name()='repository']")
    [pscustomobject]@{
        Id      = $metadata.SelectSingleNode("*[local-name()='id']").InnerText
        Version = $metadata.SelectSingleNode("*[local-name()='version']").InnerText
        Commit  = if ($repository) { $repository.GetAttribute('commit') } else { '' }
    }
}
