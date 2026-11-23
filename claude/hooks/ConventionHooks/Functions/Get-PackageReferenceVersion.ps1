function Get-PackageReferenceVersion {
    # The version of a PackageReference / PackageVersion item: its Version attribute or <Version> child; '' without one.
    param([Parameter(Mandatory)] [Xml.XmlElement] $Node)
    $version = $Node.GetAttribute('Version')
    $element = $Node.SelectSingleNode("*[local-name()='Version']")
    if (-not $version -and $element) {
        $version = $element.InnerText
    }
    $version
}
