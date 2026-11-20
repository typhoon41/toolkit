---
name: browser-verification
description: Verifying a frontend change in a real browser with Claude in Chrome before calling it done - run the app, use the changed flow like a user, measure layout at desktop, tablet, mobile and reflow widths, check console, network, keyboard and media preferences. Apply after any change to templates, styles or component structure, before reporting the work as finished.
---

# Verify UI changes in a browser

Lint, build and unit tests passing is not evidence that a UI change works. Before reporting a frontend change as
done, run the app and test it in Chrome with Claude in Chrome.

## Lint first

Run the project's lint and read its **warnings** too: warning-level rules don't fail the build, so a green CI run
is not proof the change is clean.

## Run it

Start the app the way the project documents (its `CLAUDE.md` or `run` skill). If the backend is needed, prefer the
lightest way the project offers to run it on its own.

## Test with Claude in Chrome (required)

1. Load the Claude in Chrome tools in **one** `ToolSearch` call: `tabs_context_mcp`, `tabs_create_mcp`, `navigate`,
   `computer`, `find`, `read_page`, `resize_window`, `javascript_tool`, `read_console_messages`,
   `read_network_requests`, `gif_creator`, `tabs_close_mcp` (all `mcp__claude-in-chrome__*`).
2. Call `tabs_context_mcp` first, then open a **new** tab with `tabs_create_mcp` - never reuse one of the user's
   tabs unless asked - and `navigate` it to the running app.
3. **Use the changed flow like a user**: `find` / `read_page` to locate the controls, `computer` to click, type and
   take screenshots. Exercise the happy path and at least one failure path (invalid input, an empty state).
4. For a multi-step flow, record it with `gif_creator` (extra frames before and after each action, a descriptive
   file name) so the user can review it.
5. Read `read_console_messages` with a `pattern` for the app's errors, and `read_network_requests` for failed
   calls. An error page may hide the real status code: check the actual response, not the page text.
6. Close the tab you opened with `tabs_close_mcp`.

Don't trigger `alert` / `confirm` / `prompt` dialogs: they block the extension. If an action would open one, warn
the user first.

If Claude in Chrome is not connected, or its tools keep failing after two or three attempts, stop and say the UI
was **not** verified in the browser, instead of reporting the change as done.

## Measure, don't eyeball

- Check at four widths with `resize_window`: desktop (~1440 CSS px), tablet (~800 CSS px), mobile (~390 CSS px)
  and the 320 CSS px reflow width, where nothing may scroll sideways or get cut off. Confirm the result with
  `javascript_tool` (`window.innerWidth`): on a scaled display the window size is in device pixels (at 150%,
  1440 CSS px is 2160 device px).
- Compare bounding rectangles (`getBoundingClientRect()` through `javascript_tool`) of the elements the change
  affects - alignment, size, overflow - instead of judging a screenshot.
- Tab through the changed UI with the keyboard (`computer` key presses): every control is reachable in reading
  order, focus is visible, nothing traps it.
- For a change to colours, focus styles or motion, emulate `forced-colors: active` and
  `prefers-reduced-motion: reduce`. Claude in Chrome cannot emulate media features; use the chrome-devtools MCP
  `emulate` tool for these when it is available, and say so when it is not.

## After moving markup

When markup moves between components with component-scoped stylesheets, check that every rule styling it moved
too: a rule left behind silently stops matching. Measure the moved elements again.

## Report

Say what you ran, which flows you exercised in Claude in Chrome, at which widths, and what you measured; link any
recorded GIF. Name anything you could not verify.
