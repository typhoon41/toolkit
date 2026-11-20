function Test-PatternMatch {
    # A match that exceeds the timeout counts as none, so a pathological file can neither hang nor crash the hook.
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
