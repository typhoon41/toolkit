function ConvertTo-TrustedFeedHost {
    # Host names from the comma-separated trustedFeedHosts pipeline parameter; an unresolved $(...) macro is none.
    param([AllowNull()] [AllowEmptyString()] [string] $Text)
    if (-not $Text -or $Text -match '^\$\(') {
        return , @()
    }
    , @($Text -split '[,;\s]+' | Where-Object { $_ } | ForEach-Object { $_.Trim().ToLowerInvariant() })
}
