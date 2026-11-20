function Get-PackageEntryMap {
    # Skips .signature.p7s and [Content_Types].xml, the two entries repository signing adds or rewrites.
    param([Parameter(Mandatory)] [string] $Path)
    $map = @{}
    $archive = [IO.Compression.ZipFile]::OpenRead($Path)
    $hasher = [Security.Cryptography.SHA256]::Create()
    try {
        foreach ($entry in $archive.Entries) {
            if ($entry.FullName -in '.signature.p7s', '[Content_Types].xml') {
                continue
            }
            $stream = $entry.Open()
            try {
                $map[$entry.FullName] = [Convert]::ToHexString($hasher.ComputeHash($stream))
            }
            finally {
                $stream.Dispose()
            }
        }
    }
    finally {
        $archive.Dispose()
        $hasher.Dispose()
    }
    $map
}
