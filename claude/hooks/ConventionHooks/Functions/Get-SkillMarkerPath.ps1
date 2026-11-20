function Get-SkillMarkerPath {
    # One file per session and per subagent, because a subagent does not inherit its parent's skills. Without a
    # session id, an hourly bucket keeps the gate working.
    param(
        [Parameter(Mandatory)] [object] $Payload,
        [Parameter(Mandatory)] [string] $MarkerRoot
    )
    $session = Get-PayloadValue -Payload $Payload -Name 'session_id'
    if (-not $session) {
        $session = (Get-Date).ToString('yyyyMMdd-HH')
    }
    $agent = Get-PayloadValue -Payload $Payload -Name 'agent_id'
    $name = if ($agent) { "$session-$agent" } else { $session }
    Join-Path $MarkerRoot (($name -replace '[^\w-]', '_') + '.txt')
}
