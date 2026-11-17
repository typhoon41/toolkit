function Write-ReleaseLog {
    param([AllowNull()] [AllowEmptyString()] [string] $Message)
    Write-Host (Protect-LogText $Message)
}
