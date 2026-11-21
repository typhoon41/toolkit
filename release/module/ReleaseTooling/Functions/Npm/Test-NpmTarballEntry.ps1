function Test-NpmTarballEntry {
    param([Parameter(Mandatory)] [string] $Path, [Parameter(Mandatory)] [string] $Name)
    $file = [IO.File]::OpenRead($Path)
    try {
        $gzip = [IO.Compression.GZipStream]::new($file, [IO.Compression.CompressionMode]::Decompress)
        $reader = [Formats.Tar.TarReader]::new($gzip)
        while ($null -ne ($entry = $reader.GetNextEntry())) {
            if ($entry.Name -eq "package/$Name") {
                return $true
            }
        }
        $false
    }
    finally {
        $file.Dispose()
    }
}
