function Protect-LogText {
    <#
        Untrusted text (commit messages, PR titles, API errors) must never emit an Azure Pipelines
        logging command. The agent recognises ##vso[...] and ##[...] anywhere in a line,
        case-insensitively, so the marker itself is neutralised.
    #>
    param([AllowNull()] [AllowEmptyString()] [string] $Text)
    if ($null -eq $Text) {
        return ''
    }
    $Text -replace '(?i)##(?=\[|vso\[)', '#_#'
}
