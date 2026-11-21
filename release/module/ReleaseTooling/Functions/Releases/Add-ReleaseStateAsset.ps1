function Add-ReleaseStateAsset {
    param([Parameter(Mandatory)] $Context, [Parameter(Mandatory)] $Release, [Parameter(Mandatory)] [string] $Name, [Parameter(Mandatory)] $Content)
    $file = Join-Path ([IO.Path]::GetTempPath()) "$([Guid]::NewGuid().ToString('n'))-$Name"
    try {
        $Content | ConvertTo-Json | Set-Content -LiteralPath $file -Encoding utf8
        $uploadBase = $Release.upload_url -replace '\{.*\}$', ''
        Invoke-GitHubApi -Client $Context.Client -Method Post -InFile $file -Path "${uploadBase}?name=$Name" | Out-Null
    }
    finally {
        Remove-Item -LiteralPath $file -ErrorAction SilentlyContinue
    }
}
