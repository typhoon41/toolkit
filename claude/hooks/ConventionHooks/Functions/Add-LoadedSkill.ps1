function Add-LoadedSkill {
    # Records that a skill of this plugin was loaded, in the marker file of the session or subagent.
    param(
        [Parameter(Mandatory)] [string] $MarkerPath,
        [Parameter(Mandatory)] [string] $Skill
    )
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $MarkerPath) | Out-Null
    Add-Content -LiteralPath $MarkerPath -Value $Skill -Encoding utf8NoBOM
}
