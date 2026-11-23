---
name: browser-verification
description: Verifying a frontend change in a real browser before calling it done - run the app, use the changed flow like a user, measure layout at desktop, tablet, mobile and reflow widths, check console, network, keyboard and media preferences. Apply after any change to templates, styles or component structure, before reporting the work as finished.
---

# Verify UI changes in a browser

Lint, build and unit tests passing is not evidence a UI change works: run the app and test it in a browser Claude can
drive. With Claude in Chrome, follow [claude-in-chrome.md](claude-in-chrome.md) for the tools behind each step. If no
browser automation is connected or it keeps failing, say the UI was **not** verified instead of reporting the change
as done.

1. **Lint** and read the **warnings** too: they don't fail the build.
2. **Run** the app as the project documents (its `CLAUDE.md` or `run` skill); for the backend, the lightest standalone
   way it offers.
3. **Open** a new tab - never reuse the user's tabs - and load the app.
4. **Use the changed flow like a user**: the happy path and at least one failure path (invalid input, an
   empty state). Record a multi-step flow when the tooling can. Warn the user before an action that opens an
   `alert` / `confirm` / `prompt`: it can block the automation.
5. **Console and network**: read the console for the app's errors and the network log for failed calls - an error
   page may hide the real status code, so check the response.
6. **Measure, don't eyeball**:
   - Resize to desktop (~1440), tablet (~800), mobile (~390) and reflow (320) CSS px - at 320 nothing scrolls
     sideways or is cut off. Confirm with `window.innerWidth`: on a scaled display the window size is in device pixels.
   - Compare `getBoundingClientRect()` of the affected elements (alignment, size, overflow).
   - Tab through the changed UI: reading order, visible focus, no trap.
   - For colour, focus or motion changes, emulate `forced-colors: active` and `prefers-reduced-motion: reduce`; say so
     when the tooling can't.
   - Markup moved between components: re-measure it - a style rule left behind silently stops matching.
7. **Close** the tab you opened.
8. **Report** what you ran, the flows exercised, the widths and what you measured, any recording; name what you could
   not verify.
