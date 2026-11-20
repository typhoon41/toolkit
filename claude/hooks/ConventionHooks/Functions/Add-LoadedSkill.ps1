function Add-LoadedSkill {
    param(
        [Parameter(Mandatory)] [string] $MarkerPath,
        [Parameter(Mandatory)] [string] $Skill
    )
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $MarkerPath) | Out-Null
    Add-Content -LiteralPath $MarkerPath -Value $Skill -Encoding utf8NoBOM
}
