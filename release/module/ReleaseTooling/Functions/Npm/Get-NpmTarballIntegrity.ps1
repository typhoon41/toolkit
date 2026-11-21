function Get-NpmTarballIntegrity {
    param([Parameter(Mandatory)] [string] $Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    'sha512-' + [Convert]::ToBase64String([Security.Cryptography.SHA512]::HashData($bytes))
}
