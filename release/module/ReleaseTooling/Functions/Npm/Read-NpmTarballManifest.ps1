function Read-NpmTarballManifest {
    param([Parameter(Mandatory)] [string] $Path)
    $file = [IO.File]::OpenRead($Path)
    try {
        $gzip = [IO.Compression.GZipStream]::new($file, [IO.Compression.CompressionMode]::Decompress)
        $reader = [Formats.Tar.TarReader]::new($gzip)
        while ($null -ne ($entry = $reader.GetNextEntry())) {
            if ($entry.Name -ne 'package/package.json' -or -not $entry.DataStream) {
                continue
            }
            $text = [IO.StreamReader]::new($entry.DataStream).ReadToEnd()
            return $text | ConvertFrom-Json -AsHashtable
        }
        throw "$Path contains no package/package.json."
    }
    finally {
        $file.Dispose()
    }
}
