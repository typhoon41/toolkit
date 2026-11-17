function Get-PackageEntryMap {
    <#
        name -> SHA-256 of the entry's content, for every zip entry. Ignores the two entries repository
        signing adds or rewrites (.signature.p7s and [Content_Types].xml, which gains the p7s type).
    #>
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
