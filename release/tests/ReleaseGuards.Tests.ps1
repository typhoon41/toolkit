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
