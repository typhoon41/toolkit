BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
    . (Join-Path $PSScriptRoot 'TestRepository.ps1')

    function New-TwoUnitRepository([string] $Name) {
        $repository = New-TestRepository (Join-Path $TestDrive $Name)
        Set-TestFile $repository 'release.json' '{ "units": [ { "name": "Lib", "type": "nuget", "projects": ["src/Lib/Lib.csproj"] }, { "name": "web", "type": "npm", "package": "web/package.json" } ] }'
        Set-TestFile $repository 'Directory.Build.props' (New-PropsContent '1.0.0')
        Set-TestFile $repository 'src/Lib/Lib.csproj' (New-ProjectContent)
        Set-TestFile $repository 'web/package.json' '{ "name": "@x/web", "version": "2.0.0" }'
        Save-TestCommit $repository 'feat: initial' -Tag 'Lib/v1.0.0'
        Push-Location $repository
        git tag 'web/v2.0.0'
        Pop-Location
        $repository
    }

    function Get-TestPlan([string] $Repository, [string] $Branch = 'refs/heads/main', [string] $PipelineVersion) {
        Push-Location $Repository
        try {
            New-ReleasePlan -RepositoryRoot '.' -SourceBranch $Branch -BuildId '42' -PipelineVersion $PipelineVersion
        }
        finally {
            Pop-Location
        }
    }
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

Describe 'New-ReleasePlan' {
    It 'releases a unit when only Directory.Build.props changed' {
        $repository = New-TwoUnitRepository 'props-bump'
        Set-TestFile $repository 'Directory.Build.props' (New-PropsContent '1.1.0')
        Save-TestCommit $repository 'chore: release 1.1.0'
        $plan = Get-TestPlan $repository
        $lib = $plan.units | Where-Object name -eq 'Lib'
        $lib.canRelease | Should -BeTrue
        $lib.packageVersion | Should -Be '1.1.0'
        $lib.previousTag | Should -Be 'Lib/v1.0.0'
        $lib.paths | Should -Be @('src/Lib', 'Directory.Build.props')
        ($plan.units | Where-Object name -eq 'web').canRelease | Should -BeFalse
        $plan.runName | Should -Be '1.1.0+42'
        $plan.hasRelease | Should -BeTrue
    }

    It 'releases a unit when only its csproj changed' {
        $repository = New-TwoUnitRepository 'project-bump'
        Set-TestFile $repository 'src/Lib/Lib.csproj' (New-ProjectContent '1.2.0')
        Save-TestCommit $repository 'chore: release 1.2.0'
        $lib = (Get-TestPlan $repository).units | Where-Object name -eq 'Lib'
        $lib.canRelease | Should -BeTrue
        $lib.versionSource | Should -Be 'src/Lib/Lib.csproj'
    }

    It 'releases an npm unit when package.json changed, and names the run after it' {
        $repository = New-TwoUnitRepository 'npm-bump'
        Set-TestFile $repository 'web/package.json' '{ "name": "@x/web", "version": "2.1.0-beta.1" }'
        Save-TestCommit $repository 'chore: web beta'
        $plan = Get-TestPlan $repository
        $plan.runName | Should -Be '2.1.0-beta.1+42'
        $web = $plan.units | Where-Object name -eq 'web'
        $web.canRelease | Should -BeTrue
        $web.isPrerelease | Should -BeTrue
        $web.tag | Should -Be 'web/v2.1.0-beta.1'
    }

    It 'packs CI versions with branch words on a feature branch' {
        $repository = New-TwoUnitRepository 'feature'
        Set-TestFile $repository 'src/Lib/a.cs' 'x'
        Save-TestCommit $repository 'fix: something'
        $plan = Get-TestPlan $repository -Branch 'refs/heads/features/calendar-fixes'
        ($plan.units | Where-Object name -eq 'Lib').packageVersion | Should -Be '1.0.1-calendar-fixes.42'
        $plan.hasRelease | Should -BeFalse
        $plan.runName | Should -Be '1.0.1-calendar-fixes.42'
    }

    It 'takes an application version from the pipeline' {
        $repository = New-TestRepository (Join-Path $TestDrive 'application')
        Set-TestFile $repository 'release.json' '{ "units": [ { "name": "app", "type": "pipeline" } ] }'
        Save-TestCommit $repository 'feat: first' -Tag 'v0.9.11'
        Save-TestCommit $repository 'fix: second'
        $plan = Get-TestPlan $repository -PipelineVersion '0.9.12'
        $plan.units[0].canRelease | Should -BeTrue
        $plan.units[0].tag | Should -Be 'v0.9.12'
        $plan.runName | Should -Be '0.9.12'
        (Get-TestPlan $repository -Branch 'refs/heads/features/new-login' -PipelineVersion '0.9.13').runName | Should -Be '0.9.13-new-login'
        (Get-TestPlan $repository -PipelineVersion '0.9.10').units[0].problem | Should -Match 'higher than the latest'
    }
}

Describe 'Read-ReleaseConfiguration' {
    It 'gives a single unit the v prefix and several units their own prefixes' {
        $single = Join-Path $TestDrive 'single'
        Set-TestFile $single 'release.json' '{ "units": [ { "name": "Lib", "type": "nuget", "projects": ["Lib.csproj"] } ] }'
        (Read-ReleaseConfiguration -RepositoryRoot $single).Units[0].TagPrefix | Should -Be 'v'
        $several = Join-Path $TestDrive 'several'
        Set-TestFile $several 'release.json' '{ "units": [ { "name": "A", "type": "pipeline" }, { "name": "B", "type": "pipeline", "tagPrefix": "b-v" } ] }'
        (Read-ReleaseConfiguration -RepositoryRoot $several).Units.TagPrefix | Should -Be @('A/v', 'b-v')
    }

    It 'rejects <Case>' -ForEach @(
        @{ Case = 'an unknown type'; Json = '{ "units": [ { "name": "A", "type": "maven" } ] }' }
        @{ Case = 'a nuget unit without projects'; Json = '{ "units": [ { "name": "A", "type": "nuget" } ] }' }
        @{ Case = 'duplicate names'; Json = '{ "units": [ { "name": "A", "type": "pipeline" }, { "name": "A", "type": "pipeline" } ] }' }
        @{ Case = 'a path outside the repository'; Json = '{ "units": [ { "name": "A", "type": "npm", "package": "../x/package.json" } ] }' }
    ) {
        $root = Join-Path $TestDrive ([Guid]::NewGuid().ToString('n'))
        Set-TestFile $root 'release.json' $Json
        { Read-ReleaseConfiguration -RepositoryRoot $root } | Should -Throw
    }
}
