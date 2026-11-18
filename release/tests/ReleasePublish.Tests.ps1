BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
    . (Join-Path $PSScriptRoot 'ReleaseTestContext.ps1')
    $package = New-Item -ItemType File -Path (Join-Path $TestDrive 'Lib.1.1.0.nupkg') -Value 'bytes' -Force
}

Describe 'Invoke-ReleasePublish' {
    BeforeEach {
        Mock -ModuleName ReleaseTooling Get-GitHubRelease { , @() }
        Mock -ModuleName ReleaseTooling Get-ReleaseTag { }
        Mock -ModuleName ReleaseTooling Get-GitHubTagCommit { $TestCommit }
        Mock -ModuleName ReleaseTooling Sync-ReleaseAsset { }
        Mock -ModuleName ReleaseTooling Remove-ReleaseMarker { }
        Mock -ModuleName ReleaseTooling Start-Sleep { }
        Mock -ModuleName ReleaseTooling Get-ReleaseAsset { [pscustomobject]@{ name = 'release-state.json' } } -ParameterFilter { $Name -eq 'release-state.json' }
        Mock -ModuleName ReleaseTooling Get-ReleaseAsset { }
        Mock -ModuleName ReleaseTooling Invoke-GitHubApi { New-TestDraft }
    }

    It 'refuses a draft that Prepare never marked' {
        Mock -ModuleName ReleaseTooling Get-ReleaseAsset { } -ParameterFilter { $Name -eq 'release-state.json' }
        { Invoke-ReleasePublish -Context (New-TestContext -Files @($package)) -Release (New-TestDraft) } | Should -Throw '*Prepare did not complete*'
        Should -Invoke -ModuleName ReleaseTooling Invoke-GitHubApi -Times 0 -Exactly -ParameterFilter { $Method -eq 'Patch' }
    }

    It 'keeps the draft while a package is not on the feed' {
        Mock -ModuleName ReleaseTooling Get-UnitFeedState { , @([pscustomobject]@{ Label = 'Lib 1.1.0'; State = 'Absent'; Detail = '' }) }
        { Invoke-ReleasePublish -Context (New-TestContext -Files @($package)) -Release (New-TestDraft) -FeedWaitMinutes 0 } | Should -Throw '*not on the feed yet*'
        Should -Invoke -ModuleName ReleaseTooling Invoke-GitHubApi -Times 0 -Exactly -ParameterFilter { $Method -eq 'Patch' }
    }

    It 'fails at once when the feed holds a foreign package' {
        Mock -ModuleName ReleaseTooling Get-UnitFeedState { , @([pscustomobject]@{ Label = 'Lib 1.1.0'; State = 'Foreign'; Detail = 'other commit' }) }
        { Invoke-ReleasePublish -Context (New-TestContext -Files @($package)) -Release (New-TestDraft) -FeedWaitMinutes 10 } | Should -Throw '*different package*'
        Should -Invoke -ModuleName ReleaseTooling Start-Sleep -Times 0 -Exactly
    }

    It 'waits for indexing, then publishes' {
        $script:checks = 0
        Mock -ModuleName ReleaseTooling Get-UnitFeedState {
            $script:checks++
            $state = if ($script:checks -lt 2) { 'Absent' } else { 'Published' }
            , @([pscustomobject]@{ Label = 'Lib 1.1.0'; State = $state; Detail = '' })
        }
        Invoke-ReleasePublish -Context (New-TestContext -Files @($package)) -Release (New-TestDraft) -FeedWaitMinutes 10
        Should -Invoke -ModuleName ReleaseTooling Start-Sleep -Times 1 -Exactly
        Should -Invoke -ModuleName ReleaseTooling Invoke-GitHubApi -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Patch' -and $Path -eq 'releases/1' -and $Body.draft -eq $false -and $Body.make_latest -eq 'true'
        }
    }
}
