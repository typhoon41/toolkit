BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
    . (Join-Path $PSScriptRoot 'ReleaseTestContext.ps1')
}

Describe 'Publish-ApplicationRelease' {
    BeforeEach {
        Mock -ModuleName ReleaseTooling Get-GitHubRelease { , @() }
        Mock -ModuleName ReleaseTooling Get-ReleaseTag { }
        Mock -ModuleName ReleaseTooling Get-GitHubTagCommit { $TestCommit }
        Mock -ModuleName ReleaseTooling Invoke-GitHubApi { [pscustomobject]@{ html_url = 'https://github.com/owner/demo/releases/tag/v0.9.12' } }
    }

    It 'creates a published release at the commit' {
        Publish-ApplicationRelease -Context (New-TestContext -Version '0.9.12' -Type 'pipeline')
        Should -Invoke -ModuleName ReleaseTooling Invoke-GitHubApi -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Post' -and $Path -eq 'releases' -and -not $Body.draft -and $Body.make_latest -eq 'true' -and $Body.tag_name -eq 'v0.9.12'
        }
    }

    It 'refuses when a higher version was released before it got the lock' {
        Mock -ModuleName ReleaseTooling Get-GitHubRelease { , @([pscustomobject]@{ tag_name = 'v0.9.13'; draft = $false; html_url = 'x' }) }
        { Publish-ApplicationRelease -Context (New-TestContext -Version '0.9.12' -Type 'pipeline') } | Should -Throw '*v0.9.13 is already released*'
        Should -Invoke -ModuleName ReleaseTooling Invoke-GitHubApi -Times 0 -Exactly -ParameterFilter { $Method -in 'Post', 'Patch' }
    }

    It 'only verifies an already published release' {
        Mock -ModuleName ReleaseTooling Get-GitHubRelease { , @([pscustomobject]@{ tag_name = 'v0.9.12'; draft = $false; html_url = 'x' }) }
        Publish-ApplicationRelease -Context (New-TestContext -Version '0.9.12' -Type 'pipeline')
        Should -Invoke -ModuleName ReleaseTooling Invoke-GitHubApi -Times 0 -Exactly -ParameterFilter { $Method -eq 'Post' }
    }
}
