---
name: browser-verification
description: Verifying a frontend change in a real browser with Claude in Chrome before calling it done - run the app, use the changed flow like a user, measure layout at desktop, tablet, mobile and reflow widths, check console, network, keyboard and media preferences. Apply after any change to templates, styles or component structure, before reporting the work as finished.
---

# Verify UI changes in a browser

Lint, build and unit tests passing is not evidence a UI change works: run the app and test it with Claude in Chrome.
If it is not connected or keeps failing, say the UI was **not** verified instead of reporting the change as done.

1. **Lint** and read the **warnings** too: they don't fail the build.
2. **Run** the app as the project documents (its `CLAUDE.md` or `run` skill); for the backend, the lightest standalone
   way it offers.
3. **Open** a tab: load the Claude in Chrome tools in **one** `ToolSearch` call (`tabs_context_mcp`, `tabs_create_mcp`,
   `navigate`, `computer`, `find`, `read_page`, `resize_window`, `javascript_tool`, `read_console_messages`,
   `read_network_requests`, `gif_creator`, `tabs_close_mcp`, all `mcp__claude-in-chrome__*`), call
   `tabs_context_mcp`, then `tabs_create_mcp` - never reuse the user's tabs - and `navigate` it to the app.
4. **Use the changed flow like a user**: the happy path and at least one failure path (invalid input, an
   empty state). Record a multi-step flow with `gif_creator`. Warn the user before an action that opens an
   `alert` / `confirm` / `prompt`: it blocks the extension.
5. **Console and network**: `read_console_messages` with a `pattern` for the app's errors, `read_network_requests` for
   failed calls - an error page may hide the real status code, so check the response.
6. **Measure, don't eyeball**:
   - `resize_window` to desktop (~1440), tablet (~800), mobile (~390) and reflow (320) CSS px - at 320 nothing scrolls
     sideways or is cut off. Confirm with `window.innerWidth`: on a scaled display the window size is in device pixels.
   - Compare `getBoundingClientRect()` of the affected elements (alignment, size, overflow) through `javascript_tool`.
   - Tab through the changed UI: reading order, visible focus, no trap.
   - For colour, focus or motion changes, emulate `forced-colors: active` and `prefers-reduced-motion: reduce` with
     the chrome-devtools MCP `emulate` tool (Claude in Chrome can't); say so when it is unavailable.
   - Markup moved between components: re-measure it - a style rule left behind silently stops matching.
7. **Close** the tab you opened with `tabs_close_mcp`.
8. **Report** what you ran, the flows exercised, the widths and what you measured, any GIF; name what you could not
   verify.
