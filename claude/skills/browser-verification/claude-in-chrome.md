# browser-verification with Claude in Chrome

The tools behind each step of `SKILL.md` when the browser is Claude in Chrome (all `mcp__claude-in-chrome__*`).

| Step | Tools |
|---|---|
| Load the tools | **One** `ToolSearch` call for `tabs_context_mcp`, `tabs_create_mcp`, `navigate`, `computer`, `find`, `read_page`, `resize_window`, `javascript_tool`, `read_console_messages`, `read_network_requests`, `gif_creator`, `tabs_close_mcp` |
| 3. Open | `tabs_context_mcp`, then `tabs_create_mcp`, then `navigate` it to the app |
| 4. Use the flow | `computer`, `find`, `read_page`; record a multi-step flow with `gif_creator`. A JavaScript dialog blocks the extension |
| 5. Console and network | `read_console_messages` with a `pattern` for the app's errors, `read_network_requests` |
| 6. Measure | `resize_window`; `getBoundingClientRect()` and `window.innerWidth` through `javascript_tool` |
| 6. Media preferences | Claude in Chrome can't emulate them: use the chrome-devtools MCP `emulate` tool (plugin `chrome-devtools-mcp`) |
| 7. Close | `tabs_close_mcp` |
