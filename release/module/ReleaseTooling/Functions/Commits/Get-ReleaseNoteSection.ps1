function Get-ReleaseNoteSection {
    param([AllowNull()] $ConventionalCommit)
    if (-not $ConventionalCommit) {
        return 'Chores'
    }
    if ($ConventionalCommit.Breaking) {
        return 'Breaking Changes'
    }
    switch ($ConventionalCommit.Type) {
        'feat' { return 'Features' }
        'fix' { return 'Bug Fixes' }
        'docs' { return 'Documentation' }
        default { return 'Chores' }
    }
}
