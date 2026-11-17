function Group-ReleaseNoteEntry {
    # Entries grouped by section, in release-note order; empty sections are left out.
    param([AllowEmptyCollection()] [object[]] $Entries = @())
    foreach ($section in Get-ReleaseNoteSectionOrder) {
        $items = @(@($Entries) | Where-Object { $_ -and $_.Section -eq $section })
        if ($items.Count -gt 0) {
            [pscustomobject]@{ Name = $section; Entries = $items }
        }
    }
}
