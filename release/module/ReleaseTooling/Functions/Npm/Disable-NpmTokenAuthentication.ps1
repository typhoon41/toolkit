function Disable-NpmTokenAuthentication {
    param([AllowNull()] [AllowEmptyString()] [string] $File)
    if (-not $File) {
        return
    }
    Remove-Item -LiteralPath $File -ErrorAction SilentlyContinue
    if ($env:NPM_CONFIG_USERCONFIG -eq $File) {
        Remove-Item -LiteralPath 'Env:NPM_CONFIG_USERCONFIG' -ErrorAction SilentlyContinue
    }
}
