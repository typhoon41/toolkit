Set-StrictMode -Version Latest

foreach ($file in Get-ChildItem -Path (Join-Path $PSScriptRoot 'Functions') -Filter '*.ps1') {
    . $file.FullName
}

Export-ModuleMember -Function *
