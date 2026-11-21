function New-NpmUserConfiguration {
    # The file holds only the literal ${NPM_TOKEN} reference, which npm expands, never the token.
    param([Parameter(Mandatory)] [string] $Registry)
    $registryAddress = [Uri]$Registry
    $hostAndPath = "//$($registryAddress.Authority)$($registryAddress.AbsolutePath.TrimEnd('/'))/"
    $file = Join-Path ([IO.Path]::GetTempPath()) "npmrc-$([Guid]::NewGuid().ToString('n'))"
    $content = "registry=$Registry`n$($hostAndPath):_authToken=`${NPM_TOKEN}`nalways-auth=true`n"
    [IO.File]::WriteAllText($file, $content, [Text.UTF8Encoding]::new($false))
    $file
}
