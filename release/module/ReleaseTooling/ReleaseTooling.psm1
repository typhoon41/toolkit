Set-StrictMode -Version Latest

# Classes first: functions refer to their types.
foreach ($folder in 'Classes', 'Functions') {
    foreach ($file in Get-ChildItem -Path (Join-Path $PSScriptRoot $folder) -Filter '*.ps1' -Recurse) {
        . $file.FullName
    }
}

Export-ModuleMember -Function *
