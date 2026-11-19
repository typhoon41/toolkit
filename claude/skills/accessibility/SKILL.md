---
name: accessibility
description: WCAG 2.2 Level AA rules for user-facing markup - semantics, keyboard and focus, contrast, forced colours, reflow, labels, forms, images, navigation, tables. Apply when building or reviewing UI components, forms, navigation or any user-facing template.
---

# Accessibility (WCAG 2.2 AA)

Conform to [WCAG 2.2 Level AA](https://www.w3.org/TR/WCAG22/) and go beyond it where that clearly helps users.
Never claim the result is "fully accessible"; say what was checked.

## Semantics first

- Use the project's shared components and follow an existing usage of the same pattern; don't recreate one. The
  result must still have the right accessible name, role, value and states, keyboard behaviour and focus handling.
- Without a component, prefer native elements and attributes. Add ARIA only where native semantics fall short,
  never on top of semantics that already work.
- Landmarks (`header`, `nav`, `main`, `footer`); headings introduce sections without skipping levels; one `h1`
  for the page topic, usually first in `main`.
- A descriptive `<title>`: "Page - section - site".
- Plain, people-first, inclusive wording; consistent structure and navigation order.

## Keyboard and focus

- Every interactive element is keyboard operable with a visible focus indicator and no keyboard trap; tab order
  follows reading order.
- Static content is not tabbable (`tabindex="-1"` only for programmatic focus). Hidden content - `hidden`,
  `display: none`, `visibility: hidden`, or inside `aria-hidden="true"` - contains nothing focusable.
- A skip link is the first focusable element and targets `<main id="main-content" tabindex="-1">`; it is
  visually hidden until focused.
- A composite widget (tabs, listbox, menu, date picker, grid) has one tab stop and moves focus inside with arrow
  keys, by roving `tabindex` (one item `0`, the rest `-1`) or `aria-activedescendant`.

## Contrast and colour

- Text 4.5:1 (large text - 24px, or 18.66px bold - 3:1); focus indicators and control boundaries 3:1 against
  adjacent colours, in every state (default, hover, active, focus, visited, disabled).
- Colour is never the only cue for error, success, required or selected: add text or a named icon.
- Colours come from the design tokens. No alpha (`opacity`, `rgba`, `hsla`) on text or key affordances: their
  contrast depends on the background.

## Forced colours

- The UI adapts to Windows High Contrast / forced colours by itself. Add `@media (forced-colors: active)` only
  where system defaults fall short, and use system colour keywords there (`CanvasText`, `ButtonText`,
  `ButtonBorder`), never fixed colours; don't rely on box shadows or gradients in that mode.
- No `forced-color-adjust: none` unless justified, with an accessible alternative.
- Icons follow the text colour: SVG `fill` / `stroke: currentColor`, no colours baked into the SVG.

## Reflow (320 CSS px)

- Nothing essential is lost, hidden or truncated; multi-column layouts stack, text wraps, controls stay reachable
  and operable; collapsed content is at most one click away.
- No horizontal scrolling for multi-line text: no fixed widths that force it; media gets `max-width: 100%`; flex
  children get `min-width: 0` so they can shrink; long strings get `overflow-wrap: anywhere`; avoid
  `overflow: hidden` or absolute positioning that clips content.

## Labels and forms

- Every control has a visible label that stays visible while typing and after a value is set, and a programmatic
  one (prefer `<label for>`). The accessible name contains the visible label text (voice control); repeated
  labels ("Remove") get an `aria-label` that keeps the text and adds context.
- Help text is linked with `aria-describedby`.
- Required fields are marked visually and with `aria-required="true"`.
- Errors explain how to fix the input, set `aria-invalid="true"` (removed once valid) and are linked with
  `aria-describedby`. Don't disable submit just to block it; on an invalid submit, focus the first invalid field.

## Images, navigation, tables

- Informative images: `alt` (`<img>`) or `role="img"` + `aria-label` / `aria-labelledby` (`<svg>`). Decorative:
  `alt=""` or `aria-hidden="true"`.
- Site navigation is `<nav>` with lists of links, never `role="menu"` / `menubar`. Expandable sections are toggled
  by a `<button>` with `aria-expanded`; `Escape` may close them.
- Static tabular data is a `<table>` with `<th>`. `role="grid"` only for truly interactive grids, with cells
  inside rows and arrow-key navigation.

## Before you finish

Verify each area above that the change touches, then recommend a manual check with an assistive-technology tool
(for example Accessibility Insights): automated rules catch only part of the problems.
