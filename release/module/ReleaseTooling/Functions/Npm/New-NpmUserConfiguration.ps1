function New-NpmUserConfiguration {
    <#
        A temporary npm user configuration that authenticates to -Registry with the NPM_TOKEN environment
        variable. The file holds only the literal ${NPM_TOKEN} reference (npm expands it), never the token.
        Returns the file path; point NPM_CONFIG_USERCONFIG at it and delete it afterwards.
    #>
    param([Parameter(Mandatory)] [string] $Registry)
    $uri = [Uri]$Registry
    $hostAndPath = "//$($uri.Authority)$($uri.AbsolutePath.TrimEnd('/'))/"
    $file = Join-Path ([IO.Path]::GetTempPath()) "npmrc-$([Guid]::NewGuid().ToString('n'))"
    $content = "registry=$Registry`n$($hostAndPath):_authToken=`${NPM_TOKEN}`nalways-auth=true`n"
    [IO.File]::WriteAllText($file, $content, [Text.UTF8Encoding]::new($false))
    $file
}
