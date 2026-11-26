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
        $plan.runName | Should -Be '1.1.0'
        $plan.runNameCounted | Should -BeTrue
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
        $plan.runName | Should -Be '2.1.0-beta.1'
        $web = $plan.units | Where-Object name -eq 'web'
        $web.canRelease | Should -BeTrue
        $web.isPrerelease | Should -BeTrue
        $web.tag | Should -Be 'web/v2.1.0-beta.1'
    }

    It 'counts a release-branch build without a bump under the released version' {
        $repository = New-TwoUnitRepository 'main-without-bump'
        Set-TestFile $repository 'src/Lib/a.cs' 'x'
        Save-TestCommit $repository 'fix: something'
        $plan = Get-TestPlan $repository
        ($plan.units | Where-Object name -eq 'Lib').packageVersion | Should -Be '1.0.1-ci.42'
        $plan.hasRelease | Should -BeFalse
        $plan.runName | Should -Be '1.0.0'
        $plan.runNameCounted | Should -BeTrue
    }

    It 'keeps counting under the unit released last when it is not the first unit' {
        $repository = New-TwoUnitRepository 'main-after-second-unit-release'
        Set-TestFile $repository 'web/package.json' '{ "name": "@x/web", "version": "2.1.0" }'
        Save-TestCommit $repository 'feat: web 2.1.0' -Tag 'web/v2.1.0'
        Set-TestFile $repository 'src/Lib/a.cs' 'x'
        Save-TestCommit $repository 'fix: something'
        $plan = Get-TestPlan $repository
        $plan.hasRelease | Should -BeFalse
        $plan.runName | Should -Be '2.1.0'
        $plan.runNameCounted | Should -BeTrue
    }

    It 'follows the unit released last even when its newer bump has no release yet' {
        $repository = New-TwoUnitRepository 'main-after-failed-release'
        Set-TestFile $repository 'web/package.json' '{ "name": "@x/web", "version": "2.1.0" }'
        Save-TestCommit $repository 'feat: web 2.1.0' -Tag 'web/v2.1.0'
        Set-TestFile $repository 'web/package.json' '{ "name": "@x/web", "version": "2.2.0" }'
        Save-TestCommit $repository 'feat: web 2.2.0'
        Set-TestFile $repository 'src/Lib/a.cs' 'x'
        Save-TestCommit $repository 'fix: something'
        $plan = Get-TestPlan $repository
        $plan.hasRelease | Should -BeFalse
        $plan.runName | Should -Be '2.2.0'
        $plan.runNameCounted | Should -BeTrue
    }

    It 'packs CI versions with branch words on a feature branch' {
        $repository = New-TwoUnitRepository 'feature'
        Set-TestFile $repository 'src/Lib/a.cs' 'x'
        Save-TestCommit $repository 'fix: something'
        $plan = Get-TestPlan $repository -Branch 'refs/heads/features/calendar-fixes'
        ($plan.units | Where-Object name -eq 'Lib').packageVersion | Should -Be '1.0.1-calendar-fixes.42'
        $plan.hasRelease | Should -BeFalse
        $plan.runName | Should -Be '1.0.1-calendar-fixes.42'
        $plan.runNameCounted | Should -BeFalse
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
        $plan.runNameCounted | Should -BeFalse
        (Get-TestPlan $repository -Branch 'refs/heads/features/new-login' -PipelineVersion '0.9.13').runName | Should -Be '0.9.13-new-login'
        (Get-TestPlan $repository -PipelineVersion '0.9.10').units[0].problem | Should -Match 'higher than the latest'
    }
}

Describe 'Get-RunName' {
    It 'does not repeat the branch words when a job is re-run' {
        $unitPlan = [pscustomobject]@{ type = 'pipeline'; version = '0.9.12-calendar-fixes'; isPrerelease = $true }
        (Get-RunName -UnitPlan $unitPlan -IsReleaseBranch $false -Label 'calendar-fixes').Text | Should -Be '0.9.12-calendar-fixes'
    }
}

Describe 'Get-TagRecency' {
    It 'ranks lightweight and annotated tags by history position and skips unreachable ones' {
        $repository = New-TestRepository (Join-Path $TestDrive 'recency')
        Save-TestCommit $repository 'feat: first' -Tag 'old'
        Save-TestCommit $repository 'feat: second'
        Push-Location $repository
        try {
            git tag -a 'annotated' -m 'annotated tag'
            git checkout -q -b side
            git commit -q --allow-empty -m 'feat: elsewhere'
            git tag 'unreachable'
            git checkout -q main
            $recency = Get-TagRecency
        }
        finally {
            Pop-Location
        }
        $recency['annotated'] | Should -Be 0
        $recency['old'] | Should -Be 1
        $recency.ContainsKey('unreachable') | Should -BeFalse
    }
}
