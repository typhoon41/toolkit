function Get-AllowedCommitType {
    # The Conventional Commit types of the convention (docs/CONTRIBUTING.md).
    @('feat', 'fix', 'docs', 'chore', 'test', 'ci', 'refactor', 'build', 'perf', 'style', 'revert')
}
