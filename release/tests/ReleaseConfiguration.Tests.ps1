BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
    . (Join-Path $PSScriptRoot 'TestRepository.ps1')
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
        @{ Case = 'equal tag prefixes'; Json = '{ "units": [ { "name": "A", "type": "pipeline", "tagPrefix": "v" }, { "name": "B", "type": "pipeline", "tagPrefix": "v" } ] }' }
        @{ Case = 'a tag prefix that starts with another'; Json = '{ "units": [ { "name": "A", "type": "pipeline", "tagPrefix": "a" }, { "name": "B", "type": "pipeline", "tagPrefix": "a1.0.0-foo" } ] }' }
    ) {
        $root = Join-Path $TestDrive ([Guid]::NewGuid().ToString('n'))
        Set-TestFile $root 'release.json' $Json
        { Read-ReleaseConfiguration -RepositoryRoot $root } | Should -Throw
    }
}
