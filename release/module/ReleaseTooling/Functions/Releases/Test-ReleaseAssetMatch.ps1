function Test-ReleaseAssetMatch {
    param([Parameter(Mandatory)] $Context, [Parameter(Mandatory)] $Asset, [Parameter(Mandatory)] [IO.FileInfo] $File)
    if ($Asset.state -ne 'uploaded' -or [long]$Asset.size -ne $File.Length) {
        return $false
    }
    $local = (Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $digest = $Asset.PSObject.Properties['digest']
    if ($digest -and $digest.Value) {
        return $digest.Value -eq "sha256:$local"
    }
    # No digest reported (older GitHub Enterprise): hash the actual asset content instead of trusting the size
    $download = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('n'))
    try {
        $headers = @{} + $Context.Client.Headers
        $headers.Accept = 'application/octet-stream'
        Invoke-WebRequest -Uri "$($Context.Client.ApiUrl)/repos/$($Context.Client.Repository)/releases/assets/$($Asset.id)" -Headers $headers -OutFile $download
        (Get-FileHash -LiteralPath $download -Algorithm SHA256).Hash.ToLowerInvariant() -eq $local
    }
    finally {
        Remove-Item -LiteralPath $download -ErrorAction SilentlyContinue
    }
}
