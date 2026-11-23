BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
    . (Join-Path $PSScriptRoot 'TestRepository.ps1')

    function Save-PackageCommit([string] $Repository, [string] $Version, [string] $Dependency, [string] $Message) {
        Set-TestFile $Repository 'package.json' "{ `"name`": `"@x/config`", `"version`": `"$Version`", `"dependencies`": { `"eslint`": `"$Dependency`" } }"
        Save-TestCommit $Repository $Message
        Get-TestHead $Repository
    }

    function Get-TestHead([string] $Repository) {
        Push-Location $Repository
        try {
            git rev-parse HEAD
        }
        finally {
            Pop-Location
        }
    }

    function Invoke-InRepository([string] $Repository, [scriptblock] $Script) {
        Push-Location $Repository
        try {
            & $Script
        }
        finally {
            Pop-Location
        }
    }

    function New-UntaggedRepository([string] $Name) {
        $repository = New-TestRepository (Join-Path $TestDrive $Name)
        Set-TestFile $repository 'release.json' '{ "units": [ { "name": "config", "type": "npm", "package": "package.json" } ] }'
        Save-PackageCommit $repository '1.1.5' '9.0.0' 'Initial commit.' | Out-Null
        Save-PackageCommit $repository '1.1.5' '9.1.0' 'Package upgrade.' | Out-Null
        $script:released = Save-PackageCommit $repository '1.1.6' '9.1.0' 'Bumped version.'
        Set-TestFile $repository 'index.js' 'export default [];'
        Save-TestCommit $repository 'feat: add a rule'
        Save-PackageCommit $repository '1.1.6' '9.2.0' 'build: upgrade eslint' | Out-Null
        $script:bump = Save-PackageCommit $repository '1.1.7' '9.2.0' 'chore: release 1.1.7'
        $repository
    }
}

Describe 'Previous release without release tags' {
    It 'starts after the commit that set the previous version' {
        $repository = New-UntaggedRepository 'untagged-plan'
        $plan = Invoke-InRepository $repository { New-ReleasePlan -RepositoryRoot '.' -SourceBranch 'refs/heads/main' -BuildId '42' }
        $unit = $plan.units | Where-Object name -eq 'config'
        $unit.canRelease | Should -BeTrue
        $unit.previousTag | Should -Be ''
        $unit.previousCommit | Should -Be $released
    }

    It 'limits the notes to the commits after that boundary' {
        $repository = New-UntaggedRepository 'untagged-notes'
        $unitPlan = [pscustomobject]@{ name = 'config'; tag = 'v1.1.7'; previousTag = ''; previousCommit = $released; paths = @('.') }
        $client = New-GitHubClient -Repository 'owner/demo' -Token ''
        $notes = Invoke-InRepository $repository { New-UnitReleaseNote -UnitPlan $unitPlan -Client $client -SkipPullRequests }
        $notes.EntryCount | Should -Be 3
        $notes.Markdown | Should -Not -Match 'Bumped version'
        $notes.Markdown | Should -Match "compare/$released\.\.\.v1\.1\.7"
    }

    It 'previews the next version from the commit that set the current one' {
        $repository = New-UntaggedRepository 'untagged-preview'
        $preview = Invoke-InRepository $repository { New-PreviewUnitPlan -RepositoryRoot '.' -UnitName 'config' -Version '1.2.0' }
        $preview.previousCommit | Should -Be $bump
    }

    It 'leaves the commit empty when a release tag exists' {
        $repository = New-UntaggedRepository 'tagged'
        Invoke-InRepository $repository { git tag v1.1.6 $released }
        $plan = Invoke-InRepository $repository { New-ReleasePlan -RepositoryRoot '.' -SourceBranch 'refs/heads/main' -BuildId '42' }
        $unit = $plan.units | Where-Object name -eq 'config'
        $unit.previousTag | Should -Be 'v1.1.6'
        $unit.previousCommit | Should -Be ''
    }

    It 'returns no commit when the version never changed' {
        $repository = New-TestRepository (Join-Path $TestDrive 'single-version')
        Save-PackageCommit $repository '1.0.0' '9.0.0' 'Initial commit.' | Out-Null
        $unit = [pscustomobject]@{ Name = 'config'; Type = 'npm'; Package = 'package.json'; Projects = @() }
        Get-PreviousVersionCommit -Unit $unit -Version '1.0.0' -SourceFiles @('package.json') -RepositoryRoot $repository | Should -Be ''
    }
}

Describe 'Get-PreviousReleaseReference' {
    It '<Case>' -ForEach @(
        @{ Case = 'prefers the tag'; Plan = [pscustomobject]@{ previousTag = 'v1.0.0'; previousCommit = 'abc' }; Expected = 'v1.0.0' }
        @{ Case = 'falls back to the commit'; Plan = [pscustomobject]@{ previousTag = ''; previousCommit = 'abc' }; Expected = 'abc' }
        @{ Case = 'reads a plan without previousCommit'; Plan = [pscustomobject]@{ previousTag = '' }; Expected = '' }
    ) {
        Get-PreviousReleaseReference -UnitPlan $Plan | Should -Be $Expected
    }
}
