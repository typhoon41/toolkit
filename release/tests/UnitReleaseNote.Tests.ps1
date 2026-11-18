BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
    . (Join-Path $PSScriptRoot 'TestRepository.ps1')
    $client = New-GitHubClient -Repository 'owner/demo' -Token ''
    $sha = 'a' * 40
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
