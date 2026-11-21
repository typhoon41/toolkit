function Get-PluginName {
    # The plugin manifest is the one place that names the plugin; skills are addressed as <plugin>:<skill>.
    param([string] $ManifestPath = (Join-Path $PSScriptRoot '../../../.claude-plugin/plugin.json'))
    (Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json).name
}
