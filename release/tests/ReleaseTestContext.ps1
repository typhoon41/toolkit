# Test helper: a GitHub release context like New-GitHubReleaseContext builds, without reading packages.
# Dot-source it in BeforeAll.

$script:TestCommit = 'e' * 40

function New-TestContext {
    param([string] $Version = '1.1.0', [string] $Type = 'nuget', [IO.FileInfo[]] $Files = @())
    [pscustomobject]@{
        Client     = New-GitHubClient -Repository 'owner/demo' -Token 'token'
        Unit       = [pscustomobject]@{
            name = 'Lib'; type = $Type; version = $Version; tagPrefix = 'v'; previousTag = 'v1.0.0'
            nugetSource = 'https://api.nuget.org/v3/index.json'; npmRegistry = 'https://registry.npmjs.org/'
        }
        Candidate  = ConvertTo-ReleaseVersion $Version
        Tag        = "v$Version"
        Prefix     = 'v'
        Commit     = $script:TestCommit
        Files      = @($Files)
        PackageIds = @('Lib')
    }
}

function New-TestDraft {
    [pscustomobject]@{
        id = 1; draft = $true; target_commitish = $script:TestCommit; body = ''; html_url = 'https://github.com/owner/demo/releases/tag/v1.1.0'
        upload_url = 'https://uploads.github.com/repos/owner/demo/releases/1/assets{?name,label}'
    }
}
