function ConvertTo-ReleaseNotesMarkdown {
    # GitHub release body: one "## Section" per non-empty section, then the full-changelog link.
    param(
        [AllowEmptyCollection()] [object[]] $Entries = @(),
        [AllowEmptyString()] [string] $CompareUrl
    )
    $builder = [Text.StringBuilder]::new()
    foreach ($section in Group-ReleaseNoteEntry $Entries) {
        [void]$builder.AppendLine("## $($section.Name)").AppendLine()
        foreach ($entry in $section.Entries) {
            [void]$builder.AppendLine($entry.Markdown)
        }
        [void]$builder.AppendLine()
    }
    if ($builder.Length -eq 0) {
        [void]$builder.AppendLine('No changes.').AppendLine()
    }
    if ($CompareUrl) {
        [void]$builder.AppendLine("**Full Changelog**: $CompareUrl")
    }
    $builder.ToString().TrimEnd() + "`n"
}
