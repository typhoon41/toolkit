BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
    $commit = 'e' * 40

    function New-TestContext([string] $Version = '1.1.0', [string] $Type = 'nuget', [IO.FileInfo[]] $Files = @()) {
        [pscustomobject]@{
            Client     = New-GitHubClient -Repository 'owner/demo' -Token 'token'
            Unit       = [pscustomobject]@{ name = 'Lib'; type = $Type; version = $Version; tagPrefix = 'v'; previousTag = 'v1.0.0'; nugetSource = 'https://api.nuget.org/v3/index.json' }
            Candidate  = ConvertTo-ReleaseVersion $Version
            Tag        = "v$Version"
            Prefix     = 'v'
            Commit     = $commit
            Files      = @($Files)
            PackageIds = @('Lib')
        }
    }
}

Describe 'Invoke-ReleasePrepare' {
    BeforeAll {
        $package = New-Item -ItemType File -Path (Join-Path $TestDrive 'Lib.1.1.0.nupkg') -Value 'bytes' -Force
        $notes = Join-Path $TestDrive 'Lib.md'
        Set-Content -LiteralPath $notes -Value '## Features'
        $draft = [pscustomobject]@{ id = 1; draft = $true; target_commitish = $commit; upload_url = 'https://uploads.github.com/repos/owner/demo/releases/1/assets{?name,label}'; body = '' }
        Mock -ModuleName ReleaseTooling Get-GitHubTagCommit { $null }
        Mock -ModuleName ReleaseTooling Get-ReleaseTag { }
        Mock -ModuleName ReleaseTooling Get-GitHubCollection { }
        Mock -ModuleName ReleaseTooling Invoke-GitHubApi { $draft } -ParameterFilter { $Method -eq 'Post' -and $Path -eq 'releases' }
        Mock -ModuleName ReleaseTooling Invoke-GitHubApi { }
    }

    It 'creates a draft with the notes, uploads the package, then marks it' {
        Invoke-ReleasePrepare -Context (New-TestContext -Files @($package)) -Release $null -Releases @() -PublicationStarted $false -NotesFile $notes

        Should -Invoke -ModuleName ReleaseTooling Invoke-GitHubApi -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Post' -and $Path -eq 'releases' -and $Body.draft -and $Body.tag_name -eq 'v1.1.0' -and $Body.body -match '## Features' -and $Body.target_commitish -eq $commit
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

Describe 'Publish-ApplicationRelease' {
    BeforeAll {
        Mock -ModuleName ReleaseTooling Get-GitHubRelease { , @() }
        Mock -ModuleName ReleaseTooling Get-ReleaseTag { }
        Mock -ModuleName ReleaseTooling Get-GitHubTagCommit { $commit }
        Mock -ModuleName ReleaseTooling Invoke-GitHubApi { [pscustomobject]@{ html_url = 'https://github.com/owner/demo/releases/tag/v0.9.12' } }
    }

    It 'creates a published release at the commit' {
        Publish-ApplicationRelease -Context (New-TestContext -Version '0.9.12' -Type 'pipeline')
        Should -Invoke -ModuleName ReleaseTooling Invoke-GitHubApi -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Post' -and $Path -eq 'releases' -and -not $Body.draft -and $Body.make_latest -eq 'true' -and $Body.tag_name -eq 'v0.9.12'
        }
    }

    It 'only verifies an already published release' {
        Mock -ModuleName ReleaseTooling Get-GitHubRelease { , @([pscustomobject]@{ tag_name = 'v0.9.12'; draft = $false; html_url = 'x' }) }
        Publish-ApplicationRelease -Context (New-TestContext -Version '0.9.12' -Type 'pipeline')
        Should -Invoke -ModuleName ReleaseTooling Invoke-GitHubApi -Times 0 -Exactly -ParameterFilter { $Method -eq 'Post' }
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

Describe 'Get-RunName' {
    It 'does not repeat the branch words when a job is re-run' {
        $unitPlan = [pscustomobject]@{ type = 'pipeline'; version = '0.9.12-calendar-fixes'; isPrerelease = $true }
        Get-RunName -UnitPlan $unitPlan -BuildId '1' -IsReleaseBranch $false -Label 'calendar-fixes' | Should -Be '0.9.12-calendar-fixes'
    }
}
