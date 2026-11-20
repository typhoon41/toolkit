function ConvertTo-TrustedFeedHost {
    # An unresolved $(...) macro means no trusted hosts.
    param([AllowNull()] [AllowEmptyString()] [string] $Text)
    if (-not $Text -or $Text -match '^\$\(') {
        return , @()
    }
    , @($Text -split '[,;\s]+' | Where-Object { $_ } | ForEach-Object { $_.Trim().ToLowerInvariant() })
}
