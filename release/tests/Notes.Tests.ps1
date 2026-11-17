BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
    . (Join-Path $PSScriptRoot 'TestRepository.ps1')
    $client = New-GitHubClient -Repository 'owner/demo' -Token ''
    $sha = 'a' * 40
}

Describe 'Release note rendering' {
    BeforeAll {
        $entries = @(
            New-ReleaseNoteEntry -Commit $sha -Subject 'fix: wrong day' -ConventionalCommit (Get-ConventionalCommit 'fix: wrong day') -Author 'Ana' -PullRequestNumber 7 -RepositoryUrl $client.RepositoryUrl
            New-ReleaseNoteEntry -Commit $sha -Subject 'feat!: new api' -ConventionalCommit (Get-ConventionalCommit 'feat!: new api') -Author 'Bo' -RepositoryUrl $client.RepositoryUrl
            New-ReleaseNoteEntry -Commit $sha -Subject 'updated stuff' -ConventionalCommit $null -Author 'Cy' -RepositoryUrl $client.RepositoryUrl
        )
    }

    It 'orders sections ESLint-style and links commits' {
        $markdown = ConvertTo-ReleaseNotesMarkdown -Entries $entries -CompareUrl 'https://github.com/owner/demo/compare/v1...v2'
        $markdown | Should -Match '(?s)## Breaking Changes.*## Bug Fixes.*## Chores'
        $markdown | Should -Match '\[`aaaaaaa`\]\(https://github.com/owner/demo/commit/a{40}\) fix: wrong day \(#7\) \(Ana\)'
        $markdown | Should -Match '\*\*Full Changelog\*\*: https://github.com/owner/demo/compare/v1...v2'
    }

    It 'renders plain text with a release link' {
        $text = ConvertTo-ReleaseNotesText -Entries $entries -ReleaseUrl 'https://github.com/owner/demo/releases/tag/v2'
        $text | Should -Match "Bug Fixes`n- fix: wrong day \(#7\)"
        $text | Should -Match 'Full release notes: https://github.com/owner/demo/releases/tag/v2'
        $text | Should -Not -Match '\]\('
    }

    It 'shortens long plain text at whole lines' {
        $many = @(1..500 | ForEach-Object { New-ReleaseNoteEntry -Commit $sha -Subject "fix: item $_ with a reasonably long description" -ConventionalCommit (Get-ConventionalCommit 'fix: x') -RepositoryUrl $client.RepositoryUrl })
        $text = ConvertTo-ReleaseNotesText -Entries $many -ReleaseUrl 'https://example.com/r' -MaximumLength 2000
        $text.Length | Should -BeLessOrEqual 2000
        $text | Should -Match 'Shortened; full release notes: https://example.com/r'
    }

    It 'says so when nothing changed' {
        ConvertTo-ReleaseNotesMarkdown -Entries @() | Should -Match 'No changes\.'
    }
}

Describe 'Test-PathInScope' {
    It 'matches files under a directory or equal to a file' {
        Test-PathInScope -FilePaths @('src/Lib/A.cs') -Scope @('src/Lib') | Should -BeTrue
        Test-PathInScope -FilePaths @('src/LibOther/A.cs') -Scope @('src/Lib') | Should -BeFalse
        Test-PathInScope -FilePaths @('Directory.Build.props') -Scope @('src/Lib', 'Directory.Build.props') | Should -BeTrue
        Test-PathInScope -FilePaths @('anything') -Scope @() | Should -BeTrue
    }
}

Describe 'Get-ReleaseNoteEntry with pull requests' {
    BeforeAll {
        $mergeCommit = [pscustomobject]@{ Hash = $sha; ParentCount = 1; Subject = 'Calendar fixes (#13)'; Author = 'Merger'; Body = '' }
        Mock -ModuleName ReleaseTooling Get-MergedPullRequest { [pscustomobject]@{ number = 13; title = 'Calendar fixes'; commits = 3 } }
        Mock -ModuleName ReleaseTooling Get-PullRequestCommit {
            , @(
                [pscustomobject]@{ sha = 'b' * 40; parents = @(1); commit = [pscustomobject]@{ message = 'fix: wrong day'; author = [pscustomobject]@{ name = 'Ana' } } }
                [pscustomobject]@{ sha = 'c' * 40; parents = @(1); commit = [pscustomobject]@{ message = 'wip'; author = [pscustomobject]@{ name = 'Ana' } } }
                [pscustomobject]@{ sha = 'd' * 40; parents = @(1); commit = [pscustomobject]@{ message = 'feat: web only'; author = [pscustomobject]@{ name = 'Bo' } } }
            )
        }
        Mock -ModuleName ReleaseTooling Get-GitHubCommitFile { if ($Commit -eq ('d' * 40)) { , @('web/x.ts') } else { , @('src/Lib/A.cs') } }
    }

    It 'lists the conventional commits of the PR, newest first' {
        $entries = @(Get-ReleaseNoteEntry -Client $client -Commits @($mergeCommit))
        $entries.Count | Should -Be 2
        $entries[0].Markdown | Should -Match 'feat: web only \(#13\)'
        $entries[1].Section | Should -Be 'Bug Fixes'
    }

    It 'drops PR commits outside the unit''s paths' {
        $entries = @(Get-ReleaseNoteEntry -Client $client -Commits @($mergeCommit) -Scope @('src/Lib'))
        $entries.Count | Should -Be 1
        $entries[0].Markdown | Should -Match 'fix: wrong day'
    }

    It 'falls back to the PR title as a chore when nothing conventional remains' {
        $entries = @(Get-ReleaseNoteEntry -Client $client -Commits @($mergeCommit) -Scope @('docs'))
        $entries.Count | Should -Be 1
        $entries[0].Section | Should -Be 'Chores'
        $entries[0].Markdown | Should -Match 'Calendar fixes \(#13\) \(Merger\)'
    }
}

Describe 'New-UnitReleaseNote on a repository' {
    It 'covers the commits since the previous tag that touch the unit' {
        $repository = New-TestRepository (Join-Path $TestDrive 'notes')
        Set-TestFile $repository 'src/Lib/A.cs' '1'
        Save-TestCommit $repository 'feat: first' -Tag 'Lib/v1.0.0'
        Set-TestFile $repository 'src/Lib/A.cs' '2'
        Save-TestCommit $repository 'fix: lib bug'
        Set-TestFile $repository 'web/a.ts' '1'
        Save-TestCommit $repository 'feat: web feature'
        $unitPlan = [pscustomobject]@{ name = 'Lib'; tag = 'Lib/v1.1.0'; previousTag = 'Lib/v1.0.0'; paths = @('src/Lib') }
        Push-Location $repository
        try {
            $notes = New-UnitReleaseNote -UnitPlan $unitPlan -Client $client -SkipPullRequests
        }
        finally {
            Pop-Location
        }
        $notes.EntryCount | Should -Be 1
        $notes.Markdown | Should -Match 'fix: lib bug'
        $notes.Markdown | Should -Match 'compare/Lib/v1.0.0...Lib/v1.1.0'
    }
}
