function Get-WrittenText {
    param([Parameter(Mandatory)] [AllowNull()] [object] $ToolInput)
    if ($null -eq $ToolInput) {
        return
    }
    foreach ($name in 'content', 'new_string') {
        $property = $ToolInput.PSObject.Properties[$name]
        if ($property -and $property.Value) {
            [string]$property.Value
        }
    }
    $edits = $ToolInput.PSObject.Properties['edits']
    if ($edits -and $edits.Value) {
        foreach ($edit in $edits.Value) {
            Get-WrittenText -ToolInput $edit
        }
    }
}
