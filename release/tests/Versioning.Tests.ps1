BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
}

Describe 'ConvertTo-ReleaseVersion' {
    It 'accepts <Text>' -ForEach @(
        @{ Text = '1.3.0' }, @{ Text = '0.0.1' }, @{ Text = '1.3.0-alpha' }, @{ Text = '1.3.0-beta.2' }, @{ Text = '10.20.30-rc.1.ci.4711' }
    ) {
        ConvertTo-ReleaseVersion $Text | Should -Not -BeNullOrEmpty
    }

    It 'rejects <Text>' -ForEach @(
        @{ Text = '1.3' }, @{ Text = '1.3.0.1' }, @{ Text = '01.3.0' }, @{ Text = '1.3.0-Beta' }, @{ Text = '1.3.0+build' }, @{ Text = '1.3.0-beta.01' }, @{ Text = '' }
    ) {
        ConvertTo-ReleaseVersion $Text | Should -BeNullOrEmpty
    }

    It 'splits the prerelease label' {
        $version = ConvertTo-ReleaseVersion '2.1.0-beta.3'
        $version.Major | Should -Be 2
        $version.PreRelease | Should -Be 'beta.3'
        $version.IsPrerelease | Should -BeTrue
    }
}

Describe 'Compare-ReleaseVersion' {
    It '<Left> is lower than <Right>' -ForEach @(
        @{ Left = '1.0.0-alpha'; Right = '1.0.0-alpha.1' }
        @{ Left = '1.0.0-alpha.1'; Right = '1.0.0-beta' }
        @{ Left = '1.0.0-beta.2'; Right = '1.0.0-beta.11' }
        @{ Left = '1.0.0-rc.1'; Right = '1.0.0' }
        @{ Left = '1.0.0'; Right = '1.0.1' }
        @{ Left = '1.9.0'; Right = '1.10.0' }
    ) {
        Compare-ReleaseVersion (ConvertTo-ReleaseVersion $Left) (ConvertTo-ReleaseVersion $Right) | Should -Be -1
        Compare-ReleaseVersion (ConvertTo-ReleaseVersion $Right) (ConvertTo-ReleaseVersion $Left) | Should -Be 1
    }
}

Describe 'Get-ContinuousIntegrationVersion' {
    It 'labels an unreleased stable version' {
        Get-ContinuousIntegrationVersion -Version (ConvertTo-ReleaseVersion '1.3.0') -BuildId '4711' -Label 'ci' | Should -Be '1.3.0-ci.4711'
    }
    It 'moves past an already released version' {
        Get-ContinuousIntegrationVersion -Version (ConvertTo-ReleaseVersion '1.3.0') -BuildId '4711' -Label 'calendar-fixes' -AlreadyReleased |
            Should -Be '1.3.1-calendar-fixes.4711'
    }
    It 'extends a prerelease' {
        Get-ContinuousIntegrationVersion -Version (ConvertTo-ReleaseVersion '1.3.0-beta.1') -BuildId '7' -Label 'ci' | Should -Be '1.3.0-beta.1.ci.7'
    }
    It 'always produces a valid version' {
        $text = Get-ContinuousIntegrationVersion -Version (ConvertTo-ReleaseVersion '1.3.0-beta.1') -BuildId '007' -Label 'abc-add-login'
        ConvertTo-ReleaseVersion $text | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-BranchLabel' {
    It '<Branch> -> <Expected>' -ForEach @(
        @{ Branch = 'refs/heads/features/calendar-fixes'; Expected = 'calendar-fixes' }
        @{ Branch = 'refs/heads/users/nikola/ABC-123-add-login-page-flow'; Expected = 'abc-add-login' }
        @{ Branch = 'refs/heads/bugfix/fix-the-null-check-in-parser'; Expected = 'fix-null-check' }
        @{ Branch = 'refs/heads/main'; Expected = 'main' }
        @{ Branch = 'refs/heads/feature/1234'; Expected = '' }
        @{ Branch = ''; Expected = '' }
    ) {
        Get-BranchLabel $Branch | Should -BeExactly $Expected
    }
}
