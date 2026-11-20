function Get-NpmPublishedIntegrity {
    # Only "not found" returns $null; any other failure throws, so an outage is never read as "not published".
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Version,
        [Parameter(Mandatory)] [string] $Registry
    )
    $arguments = @('view', "$Name@$Version", 'dist.integrity', '--json', '--registry', $Registry)
    $output = & npm @arguments 2>$null
    $exitCode = $LASTEXITCODE
    $text = (@($output) -join "`n").Trim()
    $result = if ($text) { try { $text | ConvertFrom-Json } catch { $null } } else { $null }

    if ($exitCode -eq 0) {
        if ($result -is [string] -and $result) {
            return $result
        }
        if (-not $text) {
            return $null
        }
        throw "npm view $Name@$Version returned an unexpected answer."
    }
    if ($result -and $result.PSObject.Properties['error'] -and $result.error.code -eq 'E404') {
        return $null
    }
    throw "npm view $Name@$Version failed (exit code $exitCode); cannot tell whether it is published."
}
