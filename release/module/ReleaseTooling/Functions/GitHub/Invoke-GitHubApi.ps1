function Invoke-GitHubApi {
    # Emits the response (arrays are enumerated). Error messages never include response bodies.
    param(
        [Parameter(Mandatory)] $Client,
        [Parameter(Mandatory)] [string] $Path,              # relative to /repos/{repository}/, or an absolute URL
        [string] $Method = 'Get',
        $Body,
        [string] $InFile,
        [switch] $AllowNotFound
    )
    $uri = if ($Path -match '^https?://') { $Path } else { "$($Client.ApiUrl)/repos/$($Client.Repository)/$Path" }
    $parameters = @{
        Uri                = $uri
        Method             = $Method
        Headers            = $Client.Headers
        SkipHttpErrorCheck = $true
        StatusCodeVariable = 'httpStatus'
    }
    if ($InFile) {
        $parameters.InFile = $InFile
        $parameters.ContentType = 'application/octet-stream'
    }
    elseif ($null -ne $Body) {
        $parameters.Body = $Body | ConvertTo-Json -Depth 10
        $parameters.ContentType = 'application/json; charset=utf-8'
    }

    $result = Invoke-RestMethod @parameters
    if ($AllowNotFound -and $httpStatus -eq 404) {
        return
    }
    if ($httpStatus -ge 400) {
        $hint = if (($httpStatus -in @(401, 403, 404)) -and -not $Client.HasToken) { ' (no token was supplied)' } else { '' }
        throw "GitHub API $Method $($uri -replace '\?.*$', '') returned HTTP $httpStatus$hint"
    }
    $result
}
