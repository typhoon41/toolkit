BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
}

Describe 'Get-ConventionalCommit and Get-ReleaseNoteSection' {
    It '<Subject> -> <Section>' -ForEach @(
        @{ Subject = 'feat: add retry policy'; Section = 'Features' }
        @{ Subject = 'fix(parser): handle empty input'; Section = 'Bug Fixes' }
        @{ Subject = 'docs: explain options'; Section = 'Documentation' }
        @{ Subject = 'feat!: drop .NET 8'; Section = 'Breaking Changes' }
        @{ Subject = 'refactor(core)!: rename option'; Section = 'Breaking Changes' }
        @{ Subject = 'perf: faster parsing'; Section = 'Chores' }
        @{ Subject = 'chore: bump Polly'; Section = 'Chores' }
        @{ Subject = 'Fix: capitalised type'; Section = 'Chores' }
        @{ Subject = 'added retry policy'; Section = 'Chores' }
        @{ Subject = 'feature: unknown type'; Section = 'Chores' }
        @{ Subject = 'fix:no space'; Section = 'Chores' }
    ) {
        Get-ReleaseNoteSection (Get-ConventionalCommit -Subject $Subject) | Should -Be $Section
    }

    It 'treats a BREAKING CHANGE footer as breaking' {
        $commit = Get-ConventionalCommit -Subject 'feat: new api' -Body "Details.`n`nBREAKING CHANGE: old api removed"
        Get-ReleaseNoteSection $commit | Should -Be 'Breaking Changes'
    }

    It 'captures the scope' {
        (Get-ConventionalCommit -Subject 'fix(calendar): wrong day').Scope | Should -Be 'calendar'
    }
}

Describe 'Test-IgnoredCommit' {
    It 'ignores merges and fixups' {
        Test-IgnoredCommit -Subject 'Merge branch main' -ParentCount 2 | Should -BeTrue
        Test-IgnoredCommit -Subject 'fixup! feat: x' -ParentCount 1 | Should -BeTrue
        Test-IgnoredCommit -Subject 'feat: x' -ParentCount 1 | Should -BeFalse
    }
}

Describe 'Protect-LogText' {
    It 'neutralises logging commands' {
        Protect-LogText 'feat: ##vso[task.setvariable variable=x]1 and ##[error]boom' | Should -Not -Match '##(vso)?\['
    }
}
