function Get-PluginSkill {
    # The skills this plugin ships: every skills/<name> folder holding a SKILL.md. The folders are the only list.
    param([string] $SkillsPath = (Join-Path $PSScriptRoot '../../../skills'))
    Get-ChildItem -LiteralPath $SkillsPath -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf } |
        ForEach-Object Name
}
