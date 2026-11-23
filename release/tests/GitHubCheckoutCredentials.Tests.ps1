BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../module/ReleaseTooling') -Force
    . (Join-Path $PSScriptRoot 'TestRepository.ps1')

    function Set-TestExtraHeader {
        param([Parameter(Mandatory)] [string] $Repository, [Parameter(Mandatory)] [string] $Key, [Parameter(Mandatory)] [string] $Header)
        git -C $Repository config --local $Key $Header
    }

    function ConvertTo-BasicCredential {
        param([Parameter(Mandatory)] [string] $Text)
        [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Text))
    }
}

Describe 'Get-CheckoutGitHubToken' {
    BeforeEach {
        $repository = New-TestRepository -Path (Join-Path $TestDrive ([Guid]::NewGuid().ToString('n')))
    }

    It 'reads the token of a basic header' {
        Set-TestExtraHeader $repository 'http.https://github.com/owner/demo.extraheader' "AUTHORIZATION: basic $(ConvertTo-BasicCredential 'x-access-token:basic-token')"
        Get-CheckoutGitHubToken -RepositoryPath $repository | Should -Be 'basic-token'
    }

    It 'reads the token of a bearer header' {
        Set-TestExtraHeader $repository 'http.extraheader' 'AUTHORIZATION: bearer bearer-token'
        Get-CheckoutGitHubToken -RepositoryPath $repository | Should -Be 'bearer-token'
    }

    It 'keeps a colon inside the token' {
        Set-TestExtraHeader $repository 'http.extraheader' "AUTHORIZATION: basic $(ConvertTo-BasicCredential 'user:to:ken')"
        Get-CheckoutGitHubToken -RepositoryPath $repository | Should -Be 'to:ken'
    }

    It 'names persistCredentials when the checkout left no credentials' {
        { Get-CheckoutGitHubToken -RepositoryPath $repository } | Should -Throw '*persistCredentials: true*'
    }

    It 'refuses a header without a token' {
        Set-TestExtraHeader $repository 'http.extraheader' "AUTHORIZATION: basic $(ConvertTo-BasicCredential 'user-only')"
        { Get-CheckoutGitHubToken -RepositoryPath $repository } | Should -Throw '*persistCredentials: true*'
    }
}

Describe 'New-GitHubClient with checkout credentials' {
    It 'authorizes with the persisted token instead of the passed one' {
        $repository = New-TestRepository -Path (Join-Path $TestDrive 'client')
        Set-TestExtraHeader $repository 'http.extraheader' 'AUTHORIZATION: bearer connection-token'
        Push-Location -LiteralPath $repository
        try {
            $client = New-GitHubClient -Repository 'owner/demo' -Token 'variable-token' -UseCheckoutCredentials
        }
        finally {
            Pop-Location
        }
        $client.Headers.Authorization | Should -Be 'Bearer connection-token'
    }
}
