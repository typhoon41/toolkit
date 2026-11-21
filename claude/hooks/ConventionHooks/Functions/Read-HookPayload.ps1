function Read-HookPayload {
    [Console]::InputEncoding = [Text.UTF8Encoding]::new($false)
    [Console]::In.ReadToEnd() | ConvertFrom-Json
}
