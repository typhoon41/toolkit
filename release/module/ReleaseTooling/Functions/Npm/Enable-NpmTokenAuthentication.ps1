function Enable-NpmTokenAuthentication {
    <#
        When the NPM_TOKEN environment variable is set, points npm at a temporary user configuration that
        authenticates to -Registry with it, and returns that file (remove it with Disable-NpmTokenAuthentication).
        Returns $null and changes nothing otherwise, e.g. when npmAuthenticate@0 prepared an .npmrc instead.
    #>
    param([Parameter(Mandatory)] [string] $Registry)
    if (-not $env:NPM_TOKEN -or $env:NPM_TOKEN -match '^\$\(') {
        return $null
    }
    $file = New-NpmUserConfiguration -Registry $Registry
    $env:NPM_CONFIG_USERCONFIG = $file
    $file
}
