function Test-PatternMatch {
    # Whether the pattern matches the text; a match that exceeds the pattern's timeout counts as no match, so a
    # pathological file can neither hang nor crash the hook.
    param(
        [Parameter(Mandatory)] [regex] $Pattern,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Text
    )
    try {
        $Pattern.IsMatch($Text)
    }
    catch [Text.RegularExpressions.RegexMatchTimeoutException] {
        $false
    }
}
