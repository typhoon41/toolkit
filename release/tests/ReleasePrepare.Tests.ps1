BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
    . (Join-Path $PSScriptRoot 'ReleaseTestContext.ps1')
    $package = New-Item -ItemType File -Path (Join-Path $TestDrive 'Lib.1.1.0.nupkg') -Value 'bytes' -Force
    $notes = Join-Path $TestDrive 'Lib.md'
    Set-Content -LiteralPath $notes -Value '## Features'
}

Describe 'Invoke-ReleasePrepare' {
    BeforeEach {
        Mock -ModuleName ReleaseTooling Get-GitHubTagCommit { $null }
        Mock -ModuleName ReleaseTooling Get-ReleaseTag { }
        Mock -ModuleName ReleaseTooling Get-GitHubCollection { }
        Mock -ModuleName ReleaseTooling Invoke-GitHubApi { New-TestDraft } -ParameterFilter { $Method -eq 'Post' -and $Path -eq 'releases' }
        Mock -ModuleName ReleaseTooling Invoke-GitHubApi { }
    }

    It 'creates a draft with the notes, uploads the package, then marks it' {
        Invoke-ReleasePrepare -Context (New-TestContext -Files @($package)) -Release $null -Releases @() -PublicationStarted $false -NotesFile $notes

        Should -Invoke -ModuleName ReleaseTooling Invoke-GitHubApi -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Post' -and $Path -eq 'releases' -and $Body.draft -and $Body.tag_name -eq 'v1.1.0' -and $Body.body -match '## Features' -and $Body.target_commitish -eq $TestCommit
        }
        Should -Invoke -ModuleName ReleaseTooling Invoke-GitHubApi -Times 1 -Exactly -ParameterFilter { $Path -like '*?name=Lib.1.1.0.nupkg' }
        Should -Invoke -ModuleName ReleaseTooling Invoke-GitHubApi -Times 1 -Exactly -ParameterFilter { $Path -like '*?name=release-state.json' }
        Should -Invoke -ModuleName ReleaseTooling Invoke-GitHubApi -Times 1 -Exactly -ParameterFilter { $Path -like '*?name=release-attempt-*' }
    }

    It 'uses a minimal body when release notes are off' {
        Invoke-ReleasePrepare -Context (New-TestContext -Files @($package)) -Release $null -Releases @() -PublicationStarted $false -NotesFile ''
        Should -Invoke -ModuleName ReleaseTooling Invoke-GitHubApi -ParameterFilter {
            $Method -eq 'Post' -and $Path -eq 'releases' -and $Body.body -match '^Release v1\.1\.0' -and $Body.body -match 'compare/v1\.0\.0\.\.\.v1\.1\.0'
        }
    }

    It 'refuses when a higher version is already released' {
        $releases = @([pscustomobject]@{ tag_name = 'v1.2.0'; draft = $false })
        { Invoke-ReleasePrepare -Context (New-TestContext -Files @($package)) -Release $null -Releases $releases -PublicationStarted $false } |
            Should -Throw '*v1.2.0 is already released*'
    }

    It 'refuses when the tag points to another commit' {
        Mock -ModuleName ReleaseTooling Get-GitHubTagCommit { 'f' * 40 }
        { Invoke-ReleasePrepare -Context (New-TestContext -Files @($package)) -Release $null -Releases @() -PublicationStarted $false } |
            Should -Throw '*already exists and points to*'
    }
}
