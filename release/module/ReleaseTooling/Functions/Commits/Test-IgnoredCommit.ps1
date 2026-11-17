function Test-IgnoredCommit {
    # Commits that may be in a pull request but never appear in release notes.
    param([AllowEmptyString()] [string] $Subject, [int] $ParentCount)
    ($ParentCount -gt 1) -or ($Subject -match '^(fixup|squash|amend)! ')
}
