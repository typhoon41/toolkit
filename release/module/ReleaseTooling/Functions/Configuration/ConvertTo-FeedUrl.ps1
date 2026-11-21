function ConvertTo-FeedUrl {
    param([AllowNull()] $Value, [Parameter(Mandatory)] [string] $Default, [Parameter(Mandatory)] [string] $Field)
    $text = if ($Value) { [string]$Value } else { $Default }
    $parsed = $null
    if (-not [Uri]::TryCreate($text, [UriKind]::Absolute, [ref]$parsed) -or $parsed.Scheme -ne 'https') {
        throw "release.json: $Field '$text' must be an absolute https:// URL."
    }
    $text
}
