function Get-NpmTarballIntegrity {
    # Subresource-integrity string npm records for a tarball: sha512-<base64>.
    param([Parameter(Mandatory)] [string] $Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    'sha512-' + [Convert]::ToBase64String([Security.Cryptography.SHA512]::HashData($bytes))
}
