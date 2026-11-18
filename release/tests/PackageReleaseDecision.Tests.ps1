BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
}

Describe 'Get-PackageReleaseDecision' {
    BeforeAll {
        $releases = @(ConvertTo-ReleaseTag -TagName 'v1.0.0' -Prefix 'v'; ConvertTo-ReleaseTag -TagName 'v1.1.0-beta.1' -Prefix 'v')
    }
    It '<Case>' -ForEach @(
        @{ Case = 'releases a bump on the release branch'; Version = '1.1.0'; Previous = '1.0.0'; Branch = $true; CanRelease = $true; Problem = $false }
        @{ Case = 'does not release on a feature branch'; Version = '1.1.0'; Previous = '1.0.0'; Branch = $false; CanRelease = $false; Problem = $false }
        @{ Case = 'does not release without a bump'; Version = '1.1.0'; Previous = '1.1.0'; Branch = $true; CanRelease = $false; Problem = $false }
        @{ Case = 'does not re-release a tagged version'; Version = '1.0.0'; Previous = '1.0.0'; Branch = $true; CanRelease = $false; Problem = $false }
        @{ Case = 'fails when bumping to a released version'; Version = '1.0.0'; Previous = '0.9.0'; Branch = $true; CanRelease = $false; Problem = $true }
        @{ Case = 'fails below the latest release'; Version = '1.0.1-alpha'; Previous = '1.0.0'; Branch = $true; CanRelease = $false; Problem = $true }
        @{ Case = 'fails below a prerelease'; Version = '1.1.0-alpha'; Previous = '1.0.0'; Branch = $false; CanRelease = $false; Problem = $true }
    ) {
        $decision = Get-PackageReleaseDecision -Candidate (ConvertTo-ReleaseVersion $Version) -PreviousText $Previous -Releases $releases `
            -IsReleaseBranch $Branch -VersionSource 'Directory.Build.props'
        $decision.CanRelease | Should -Be $CanRelease
        [bool]$decision.Problem | Should -Be $Problem
    }
}
