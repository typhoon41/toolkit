BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
    . (Join-Path $PSScriptRoot 'ReleaseTestContext.ps1')
}

Describe 'Find-UnitRelease' {
    It 'ignores other units and refuses a different spelling of the same version' {
        $context = New-TestContext -Version '1.3.0-beta.1'
        $releases = @(
            [pscustomobject]@{ tag_name = 'web/v1.3.0-beta.1'; draft = $true }
            [pscustomobject]@{ tag_name = 'v1.3.0-Beta.1'; draft = $true }
        )
        { Find-UnitRelease -Context $context -Releases $releases } | Should -Throw '*different tag spelling*'
        Find-UnitRelease -Context $context -Releases @($releases[0]) | Should -BeNullOrEmpty
    }
}

Describe 'Assert-AbandonAllowed' {
    BeforeAll {
        $release = [pscustomobject]@{ id = 1 }
        $marker = [pscustomobject]@{ created_at = [DateTime]::UtcNow.AddMinutes(-5) }
        Mock -ModuleName ReleaseTooling Get-ReleaseAsset { }
    }

    It 'refuses while this build''s package is on the feed and nothing collides' {
        { Assert-AbandonAllowed -Context (New-TestContext) -Release $release -Marker $marker -Published @('Lib 1.1.0') -Foreign @() } |
            Should -Throw '*Complete the release instead*'
    }

    It 'allows a proven collision' {
        { Assert-AbandonAllowed -Context (New-TestContext) -Release $release -Marker $marker -Published @() -Foreign @('Lib 1.1.0') } | Should -Not -Throw
    }

    It 'waits for indexing when nothing is on the feed' {
        { Assert-AbandonAllowed -Context (New-TestContext) -Release $release -Marker $marker -Published @() -Foreign @() } | Should -Throw '*may still be indexing*'
        { Assert-AbandonAllowed -Context (New-TestContext) -Release $release -Marker $marker -Published @() -Foreign @() -MinimumAgeMinutes 1 } | Should -Not -Throw
    }
}

Describe 'Test-PublicationStarted' {
    BeforeAll {
        Mock -ModuleName ReleaseTooling Get-ReleaseAsset { }
        Mock -ModuleName ReleaseTooling Get-NuGetFeedHeader { @{} }
        Mock -ModuleName ReleaseTooling Get-NuGetFlatContainer { 'https://api.nuget.org/v3-flatcontainer/' }
    }

    It 'reads the <Type> feed when the draft has no marker' -ForEach @(
        @{ Type = 'nuget'; OnFeed = $true }, @{ Type = 'nuget'; OnFeed = $false }
        @{ Type = 'npm'; OnFeed = $true }, @{ Type = 'npm'; OnFeed = $false }
    ) {
        Mock -ModuleName ReleaseTooling Test-NuGetVersion { $OnFeed }
        Mock -ModuleName ReleaseTooling Get-NpmPublishedIntegrity { if ($OnFeed) { 'sha512-x' } }
        Test-PublicationStarted -Context (New-TestContext -Type $Type) -VersionText '1.1.0' -Release ([pscustomobject]@{ id = 1 }) |
            Should -Be $OnFeed
    }
}

Describe 'Sync-ReleaseAsset' {
    BeforeAll {
        $package = New-Item -ItemType File -Force -Path (Join-Path $TestDrive 'Lib.1.1.0.nupkg')
        $assets = @(
            [pscustomobject]@{ id = 1; name = 'Lib.1.1.0.nupkg' }
            [pscustomobject]@{ id = 2; name = 'release-state.json' }
            [pscustomobject]@{ id = 3; name = 'release-state.superseded.json' }
            [pscustomobject]@{ id = 4; name = 'release-attempt-20261126T101500Z-0123abcd.json' }
            [pscustomobject]@{ id = 5; name = 'Lib.1.0.9.nupkg' }
        )
        Mock -ModuleName ReleaseTooling Get-ReleaseAsset { $assets }
        Mock -ModuleName ReleaseTooling Test-ReleaseAssetMatch { $true }
        Mock -ModuleName ReleaseTooling Invoke-GitHubApi { }
    }

    It 'removes only assets that are neither this build''s files nor release-state files' {
        Sync-ReleaseAsset -Context (New-TestContext -Files @($package)) -Release (New-TestDraft)
        Should -Invoke -ModuleName ReleaseTooling Invoke-GitHubApi -Times 1 -Exactly -ParameterFilter { $Method -eq 'Delete' }
        Should -Invoke -ModuleName ReleaseTooling Invoke-GitHubApi -Times 1 -Exactly -ParameterFilter { $Path -eq 'releases/assets/5' }
    }

    It 'refuses the stale asset when only verifying' {
        { Sync-ReleaseAsset -Context (New-TestContext -Files @($package)) -Release (New-TestDraft) -VerifyOnly -FrozenReason 'Frozen.' } |
            Should -Throw '*asset this build didn''t produce: Lib.1.0.9.nupkg*'
    }
}
