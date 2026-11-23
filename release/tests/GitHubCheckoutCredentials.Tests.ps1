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

Describe 'Checkout credentials of the toolkit' {
    It 'reads the toolkit checkout by default, the one made with the endpoint connection' {
        Mock Invoke-Git -ModuleName ReleaseTooling { 'http.https://github.com/owner/toolkit.extraheader AUTHORIZATION: bearer endpoint-token' }
        Get-CheckoutGitHubToken | Should -Be 'endpoint-token'
        $toolkitRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
        Should -Invoke Invoke-Git -ModuleName ReleaseTooling -Times 1 -ParameterFilter {
            [IO.Path]::GetFullPath($Arguments[1]).TrimEnd('\', '/') -eq $toolkitRoot.TrimEnd('\', '/')
        }
    }

    It 'authorizes the client with the persisted token instead of the passed one' {
        Mock Get-CheckoutGitHubToken -ModuleName ReleaseTooling { 'endpoint-token' }
        $client = New-GitHubClient -Repository 'owner/demo' -Token 'variable-token' -UseCheckoutCredentials
        $client.Headers.Authorization | Should -Be 'Bearer endpoint-token'
    }
}
