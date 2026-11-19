function Read-HookPayload {
    # The JSON payload Claude Code sends a hook on stdin, as an object.
    [Console]::InputEncoding = [Text.UTF8Encoding]::new($false)
    [Console]::In.ReadToEnd() | ConvertFrom-Json
}
