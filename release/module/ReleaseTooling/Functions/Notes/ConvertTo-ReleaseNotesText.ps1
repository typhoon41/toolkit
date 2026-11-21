function ConvertTo-ReleaseNotesText {
    # nuget.org shows release notes as plain text.
    param(
        [AllowEmptyCollection()] [object[]] $Entries = @(),
        [AllowEmptyString()] [string] $ReleaseUrl,
        [int] $MaximumLength = 30000
    )
    $lines = [Collections.Generic.List[string]]::new()
    foreach ($section in Group-ReleaseNoteEntry $Entries) {
        if ($lines.Count -gt 0) {
            $lines.Add('')
        }
        $lines.Add($section.Name)
        foreach ($entry in $section.Entries) {
            $lines.Add($entry.Text)
        }
    }
    if ($lines.Count -eq 0) {
        $lines.Add('No changes.')
    }

    $footer = if ($ReleaseUrl) { "Full release notes: $ReleaseUrl" } else { '' }
    $shortened = $false
    while ($lines.Count -gt 1 -and (($lines -join "`n").Length + $footer.Length + 40) -gt $MaximumLength) {
        $lines.RemoveAt($lines.Count - 1)
        $shortened = $true
    }
    if ($shortened) {
        $lines.Add('- ...')
        $footer = if ($ReleaseUrl) { "Shortened; full release notes: $ReleaseUrl" } else { 'Shortened.' }
    }
    if ($footer) {
        $lines.Add('')
        $lines.Add($footer)
    }
    ($lines -join "`n") + "`n"
}
