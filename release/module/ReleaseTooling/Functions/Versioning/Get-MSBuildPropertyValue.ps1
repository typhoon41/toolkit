function Get-MSBuildPropertyValue {
    <#
        Value of the last non-empty <Name> in the top-level PropertyGroups of an MSBuild file (the last one wins,
        as in MSBuild), or $null. A conditional definition (Condition on the property or its PropertyGroup, or
        inside Choose/When/Otherwise) is refused: which one applies depends on the build, not on the file.
    #>
    param([Parameter(Mandatory)] [string] $XmlText, [Parameter(Mandatory)] [string] $Name, [string] $FilePath)
    try {
        $document = [xml]$XmlText
    }
    catch {
        throw "$FilePath is not valid XML: $($_.Exception.Message)"
    }
    $conditional = "//*[local-name()='PropertyGroup']/*[local-name()='$Name'][@Condition or parent::*[@Condition] or " +
                   "ancestor::*[local-name()='Choose']]"       # property definitions only, not e.g. PackageReference/Version
    if ($document.SelectSingleNode($conditional)) {
        throw "${FilePath}: a conditional <$Name> is not supported; set one unconditional <$Name>."
    }
    $query = "/*[local-name()='Project']/*[local-name()='PropertyGroup']/*[local-name()='$Name']"
    $values = @($document.SelectNodes($query) | ForEach-Object { $_.InnerText.Trim() } | Where-Object { $_ })
    if ($values.Count -eq 0) {
        return $null
    }
    $values[-1]
}
