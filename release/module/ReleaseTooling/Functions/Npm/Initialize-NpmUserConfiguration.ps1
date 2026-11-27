function Initialize-NpmUserConfiguration {
    # npmAuthenticate@0 only adds credentials to an .npmrc that exists, and fails when there is none.
    param(
        [Parameter(Mandatory)] [string] $Path,
        [string] $Registry = 'https://registry.npmjs.org/'
    )
    if (Test-Path -LiteralPath $Path) {
        return $false
    }
    [IO.File]::WriteAllText($Path, "registry=$Registry`n", [Text.UTF8Encoding]::new($false))
    $true
}
