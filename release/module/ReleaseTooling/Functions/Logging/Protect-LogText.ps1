function Protect-LogText {
    # The agent runs ##vso[...] and ##[...] anywhere in a line, case-insensitively, so untrusted text (commit
    # messages, PR titles, API errors) gets the marker itself neutralised.
    param([AllowNull()] [AllowEmptyString()] [string] $Text)
    if ($null -eq $Text) {
        return ''
    }
    $Text -replace '(?i)##(?=\[|vso\[)', '#_#'
}
