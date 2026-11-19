---
name: browser-verification
description: Verifying a frontend change in a real browser before calling it done - run the app, measure layout at desktop, tablet and mobile widths, check where moved styles live. Apply after any change to templates, styles or component structure, before reporting the work as finished.
---

# Verify UI changes in a browser

Lint, build and unit tests passing is not evidence that a UI change works. Before reporting a frontend change as
done, run the app and look.

## Run it

- Start the app the way the project documents (its `CLAUDE.md` or `run` skill). If the backend is needed, prefer
  the lightest way the project offers to run it on its own.
- Use the browser tools available in the session (chrome-devtools MCP, Claude in Chrome). If none is available,
  say so instead of claiming the change was verified.

## Measure, don't eyeball

- Check at three widths: desktop (~1440 CSS px), tablet (~800 CSS px) and mobile (~390 CSS px).
- Compare bounding rectangles (`getBoundingClientRect()`) of the elements the change affects - alignment, size,
  overflow - instead of judging a screenshot.
- Viewport emulation may work in device pixels on a scaled display: set the `mobile` / device-scale flag, or
  multiply by the display scale (at 150%, 1440 CSS px is 2160 device px), and confirm `window.innerWidth`.
- Read the console and the failed network requests. An error page may hide the real status code: check the
  actual response, not the page text.

## After moving markup

When markup moves between components, every rule that styled it must move to the stylesheet of the component
that now renders the element (see `html-scss`, host elements). Stylesheets are encapsulated per component, so a
rule left behind silently stops matching.

## Report

Say what you ran, at which widths, and what you measured. Name anything you could not verify.
