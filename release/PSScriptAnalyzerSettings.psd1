@{
    ExcludeRules = @(
        # Azure Pipelines reads logging commands (##vso[...]) from the host output; Write-Host is the channel.
        'PSAvoidUsingWriteHost',
        # The scripts run non-interactively in pipelines; -WhatIf/-Confirm would never be used.
        'PSUseShouldProcessForStateChangingFunctions',
        # Every file under Functions/ is one public function; listing them twice would drift.
        'PSUseToExportFieldsInManifest',
        # The module requires PowerShell 7.2+, which reads UTF-8 without a BOM; the BOM only matters to Windows PowerShell 5.1.
        'PSUseBOMForUnicodeEncodedFile'
    )
}
