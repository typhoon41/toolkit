function Get-MSBuildPropertyValue {
    # Value of the last non-empty <Name> in any PropertyGroup of an MSBuild file (the last one wins), or $null.
    param([Parameter(Mandatory)] [string] $XmlText, [Parameter(Mandatory)] [string] $Name, [string] $FilePath)
    try {
        $document = [xml]$XmlText
    }
    catch {
        throw "$FilePath is not valid XML: $($_.Exception.Message)"
    }
    $query = "/*[local-name()='Project']/*[local-name()='PropertyGroup']/*[local-name()='$Name']"
    $values = @($document.SelectNodes($query) | ForEach-Object { $_.InnerText.Trim() } | Where-Object { $_ })
    if ($values.Count -eq 0) {
        return $null
    }
    $values[-1]
}
