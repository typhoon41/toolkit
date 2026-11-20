function Get-VersionProblem {
    param([AllowNull()] [AllowEmptyString()] [string] $Text)
    if (-not $Text) {
        return 'it is empty'
    }
    if ($Text -match '\+') {
        return 'build metadata (+...) is not allowed'
    }
    if ($Text -cmatch '[A-Z]') {
        return 'prerelease labels must be lowercase (NuGet treats Beta and beta as the same version)'
    }
    if ($Text -match '(^|\.)0[0-9]') {
        return 'numbers must not have leading zeros (e.g. 01 or beta.01)'
    }
    if ($Text -notmatch '^\d+\.\d+\.\d+') {
        return 'it must start with major.minor.patch, e.g. 1.3.0'
    }
    'it must look like 1.3.0, 1.3.0-alpha or 1.3.0-beta.1'
}
