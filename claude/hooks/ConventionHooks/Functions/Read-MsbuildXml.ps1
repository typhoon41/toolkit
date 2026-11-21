function Read-MsbuildXml {
    # An MSBuild file as XML (comments are not elements, either quote style works); nothing when it is not XML.
    param([Parameter(Mandatory)] [string] $Path)
    try {
        $document = [xml]::new()
        $document.Load($Path)
        $document
    }
    catch {
        return
    }
}
