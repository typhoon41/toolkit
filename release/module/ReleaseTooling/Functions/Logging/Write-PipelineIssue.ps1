function Write-PipelineIssue {
    param(
        [Parameter(Mandatory)] [ValidateSet('error', 'warning')] [string] $Type,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Message
    )
    $clean = (Protect-LogText $Message) -replace '[\r\n]+', ' '
    Write-Host "##vso[task.logissue type=$Type]$clean"
}
