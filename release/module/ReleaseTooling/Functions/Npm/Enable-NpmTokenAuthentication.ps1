function Enable-NpmTokenAuthentication {
    <#
        When the NPM_TOKEN environment variable is set, points npm at a temporary user configuration that
        authenticates to -Registry with it, and returns that file (remove it with Disable-NpmTokenAuthentication).
        The token goes only to npmjs.org, Azure Artifacts or a -TrustedHost; any other registry is refused.
        Returns $null and changes nothing without a token, e.g. when npmAuthenticate@0 prepared an .npmrc instead.
    #>
    param([Parameter(Mandatory)] [string] $Registry, [AllowEmptyCollection()] [string[]] $TrustedHost = @())
    if (-not $env:NPM_TOKEN -or $env:NPM_TOKEN -match '^\$\(') {
        return $null
    }
    if ((Get-FeedHostKind -Url $Registry -TrustedHost $TrustedHost) -notin 'Npmjs', 'AzureArtifacts', 'Trusted') {
        throw (Get-UntrustedFeedMessage -Url $Registry -VariableName 'NPM_TOKEN')
    }
    $file = New-NpmUserConfiguration -Registry $Registry
    $env:NPM_CONFIG_USERCONFIG = $file
    $file
}
