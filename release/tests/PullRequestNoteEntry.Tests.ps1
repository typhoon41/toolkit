BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
    $client = New-GitHubClient -Repository 'owner/demo' -Token ''
    $mergeCommit = [pscustomobject]@{ Hash = 'a' * 40; ParentCount = 1; Subject = 'Calendar fixes (#13)'; Author = 'Merger'; Body = '' }

    function New-ApiCommit([string] $Character, [string] $Message, [int] $ParentCount = 1) {
        [pscustomobject]@{
            sha = $Character * 40; parents = @(1..$ParentCount)
            commit = [pscustomobject]@{ message = $Message; author = [pscustomobject]@{ name = 'Ana' } }
        }
    }

    function Get-TestEntry([string[]] $Scope = @()) {
        @(Get-ReleaseNoteEntry -Client $client -Commits @($mergeCommit) -Scope $Scope)
    }
}

Describe 'Get-PullRequestNoteEntry' {
    BeforeEach {
        Mock -ModuleName ReleaseTooling Get-MergedPullRequest { [pscustomobject]@{ number = 13; title = 'feat: calendar'; commits = 3 } }
        Mock -ModuleName ReleaseTooling Get-PullRequestCommit {
            , @((New-ApiCommit 'b' 'fix: wrong day'), (New-ApiCommit 'c' 'wip'), (New-ApiCommit 'd' 'feat: web only'))
        }
        Mock -ModuleName ReleaseTooling Get-GitHubCommitFile { if ($Commit -eq ('d' * 40)) { , @('web/x.ts') } else { , @('src/Lib/A.cs') } }
    }

    It 'lists every inner commit newest first, non-conventional ones as chores' {
        $entries = Get-TestEntry
        $entries.Section | Should -Be @('Features', 'Chores', 'Bug Fixes')
        $entries[1].Markdown | Should -Match 'wip \(#13\)'
    }

    It 'keeps only the inner commits within the unit''s paths' {
        $entries = Get-TestEntry -Scope @('src/Lib')
        $entries.Section | Should -Be @('Chores', 'Bug Fixes')
    }

    It 'lists nothing when no inner commit touches the unit' {
        Get-TestEntry -Scope @('docs') | Should -HaveCount 0
    }

    It 'uses the PR title when no inner commit is conventional' {
        Mock -ModuleName ReleaseTooling Get-PullRequestCommit { , @((New-ApiCommit 'b' 'wip'), (New-ApiCommit 'c' 'more wip')) }
        $entries = Get-TestEntry -Scope @('src/Lib')
        $entries.Count | Should -Be 1
        $entries[0].Section | Should -Be 'Features'
        $entries[0].Markdown | Should -Match 'feat: calendar \(#13\) \(Merger\)'
    }

    It 'uses the PR title when only merge and fixup commits remain' {
        Mock -ModuleName ReleaseTooling Get-PullRequestCommit { , @((New-ApiCommit 'b' 'fixup! feat: x'), (New-ApiCommit 'c' 'Merge main' -ParentCount 2)) }
        (Get-TestEntry).Markdown | Should -Match 'feat: calendar'
    }

    It 'uses the PR title for a unit-scoped release when only merge and fixup commits remain' {
        Mock -ModuleName ReleaseTooling Get-PullRequestCommit { , @((New-ApiCommit 'b' 'squash! fix: x'), (New-ApiCommit 'c' 'Merge main' -ParentCount 2)) }
        $entries = Get-TestEntry -Scope @('src/Lib')
        $entries.Count | Should -Be 1
        $entries[0].Markdown | Should -Match 'feat: calendar'
        Should -Invoke -ModuleName ReleaseTooling Get-GitHubCommitFile -Times 0 -Exactly    # the merge commit already matched the unit's paths
    }

    It 'uses the PR title, with a warning, when GitHub cannot list the commits' {
        Mock -ModuleName ReleaseTooling Get-PullRequestCommit { throw 'PR #13 has 300 commits but GitHub returned only 250.' }
        Mock -ModuleName ReleaseTooling Write-PipelineIssue { }
        (Get-TestEntry).Markdown | Should -Match 'feat: calendar'
        Should -Invoke -ModuleName ReleaseTooling Write-PipelineIssue -Times 1 -Exactly -ParameterFilter { $Type -eq 'warning' }
    }

    It 'treats a non-conventional title as a chore' {
        Mock -ModuleName ReleaseTooling Get-MergedPullRequest { [pscustomobject]@{ number = 13; title = 'Calendar fixes'; commits = 1 } }
        Mock -ModuleName ReleaseTooling Get-PullRequestCommit { , @((New-ApiCommit 'b' 'wip')) }
        (Get-TestEntry).Section | Should -Be 'Chores'
    }
}
