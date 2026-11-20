function Test-IgnoredCommit {
    param([AllowEmptyString()] [string] $Subject, [int] $ParentCount)
    ($ParentCount -gt 1) -or ($Subject -match '^(fixup|squash|amend)! ')
}
