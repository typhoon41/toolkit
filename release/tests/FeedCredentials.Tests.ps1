BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
    . (Join-Path $PSScriptRoot 'TestRepository.ps1')
}

Describe 'Get-FeedHostKind' {
    It '<Url> is <Kind>' -ForEach @(
        @{ Url = 'https://api.nuget.org/v3/index.json'; Kind = 'NuGetOrg' }
        @{ Url = 'https://registry.npmjs.org/'; Kind = 'Npmjs' }
        @{ Url = 'https://pkgs.dev.azure.com/org/_packaging/feed/nuget/v3/index.json'; Kind = 'AzureArtifacts' }
        @{ Url = 'https://contoso.pkgs.visualstudio.com/_packaging/feed/npm/registry/'; Kind = 'AzureArtifacts' }
        @{ Url = 'https://nuget.pkg.github.com/owner/index.json'; Kind = 'Trusted' }
        @{ Url = 'https://pkgs.dev.azure.com.attacker.io/index.json'; Kind = 'Untrusted' }
        @{ Url = 'https://evil.example/registry/'; Kind = 'Untrusted' }
        @{ Url = 'http://pkgs.dev.azure.com/org/index.json'; Kind = 'Untrusted' }
    ) {
        Get-FeedHostKind -Url $Url -TrustedHost @('nuget.pkg.github.com') | Should -Be $Kind
    }
}

Describe 'Credentials per feed host' {
    BeforeEach {
        $env:NUGET_FEED_READ_TOKEN = 'read-token'
        $env:NUGET_API_KEY = 'push-key'
        $env:NPM_TOKEN = 'npm-token'
    }
    AfterEach {
        Remove-Item Env:NUGET_FEED_READ_TOKEN, Env:NUGET_API_KEY, Env:NPM_TOKEN, Env:NPM_CONFIG_USERCONFIG -ErrorAction SilentlyContinue
    }

    It 'sends the feed read token only to Azure Artifacts' {
        (Get-NuGetFeedHeader -Source 'https://pkgs.dev.azure.com/org/_packaging/feed/nuget/v3/index.json').Keys | Should -Contain 'Authorization'
        (Get-NuGetFeedHeader -Source 'https://evil.example/v3/index.json').Count | Should -Be 0
        (Get-NuGetFeedHeader -Source 'https://api.nuget.org/v3/index.json').Count | Should -Be 0
    }

    It 'chooses the push key by host' {
        Get-NuGetPushApiKey -Source 'https://api.nuget.org/v3/index.json' | Should -Be 'push-key'
        Get-NuGetPushApiKey -Source 'https://pkgs.dev.azure.com/org/_packaging/feed/nuget/v3/index.json' | Should -Be 'az'
        Get-NuGetPushApiKey -Source 'https://nuget.pkg.github.com/owner/index.json' -TrustedHost @('nuget.pkg.github.com') | Should -Be 'push-key'
        { Get-NuGetPushApiKey -Source 'https://evil.example/v3/index.json' } | Should -Throw '*evil.example is not a known feed host*'
    }

    It 'gives the npm token only to known registries' {
        { Enable-NpmTokenAuthentication -Registry 'https://evil.example/registry/' } | Should -Throw '*not a known feed host*'
        $file = Enable-NpmTokenAuthentication -Registry 'https://registry.npmjs.org/'
        try {
            $file | Should -Exist
        }
        finally {
            Disable-NpmTokenAuthentication $file
        }
        Remove-Item Env:NPM_TOKEN
        Enable-NpmTokenAuthentication -Registry 'https://evil.example/registry/' | Should -BeNullOrEmpty
    }

    It 'reads trusted hosts from the pipeline parameter' {
        $hosts = ConvertTo-TrustedFeedHost 'Nuget.Pkg.GitHub.com, npm.pkg.github.com'
        $hosts | Should -Be @('nuget.pkg.github.com', 'npm.pkg.github.com')
        (ConvertTo-TrustedFeedHost '$(TrustedFeedHosts)').Count | Should -Be 0
    }
}

Describe 'Feed URLs in release.json' {
    It 'rejects <Url>' -ForEach @(@{ Url = 'http://example.com/index.json' }, @{ Url = 'feeds/index.json' }) {
        $root = Join-Path $TestDrive ([Guid]::NewGuid().ToString('n'))
        Set-TestFile $root 'release.json' "{ `"units`": [ { `"name`": `"A`", `"type`": `"nuget`", `"projects`": [`"A.csproj`"], `"nugetSource`": `"$Url`" } ] }"
        { Read-ReleaseConfiguration -RepositoryRoot $root } | Should -Throw '*must be an absolute https:// URL*'
    }
}
