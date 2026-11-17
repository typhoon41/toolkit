function Set-PipelineVariable {
    # Only for values this code has validated itself; never for untrusted text.
    param(
        [Parameter(Mandatory)] [ValidatePattern('^[A-Za-z][A-Za-z0-9_]*$')] [string] $Name,
        [Parameter(Mandatory)] [ValidatePattern('^[A-Za-z0-9._+-]*$')] [AllowEmptyString()] [string] $Value,
        [switch] $Output
    )
    $flag = if ($Output) { ';isOutput=true' } else { '' }
    Write-Host "##vso[task.setvariable variable=$Name$flag]$Value"
}
