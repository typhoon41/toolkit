function Get-ReleaseNoteSection {
    <#
        Section a commit belongs to, ESLint-style. Without -ConventionalCommit (the message did not
        follow the convention) the commit is a chore.
    #>
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
