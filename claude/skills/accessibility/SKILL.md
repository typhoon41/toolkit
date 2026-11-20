---
name: accessibility
description: WCAG 2.2 Level AA rules for user-facing markup - semantics, keyboard and focus, states, target size, contrast, forced colours, reflow, labels and forms, navigation, tables. Apply when building or reviewing UI components, forms, navigation or any user-facing template.
---

# Accessibility (WCAG 2.2 AA)

Conform to [WCAG 2.2 Level AA](https://www.w3.org/TR/WCAG22/), beyond it where that clearly helps; the rules below are
the decisions and the often-missed points. Never claim "fully accessible": say what was checked.

## Semantics

- Use the project's shared component or an existing usage of the pattern; the result still needs the right name,
  role, value, states, keyboard behaviour and focus handling.
- Otherwise native elements first; ARIA only where native semantics fall short, never on top of working ones.
- `<title>` reads "Page - section - site".

## Keyboard and focus

- Static content is not tabbable (`tabindex="-1"` only for programmatic focus). Hidden content (`hidden`,
  `display: none`, `visibility: hidden`, inside `aria-hidden="true"`) contains nothing focusable.
- A skip link is the first focusable element, visually hidden until focused, targeting
  `<main id="main-content" tabindex="-1">`.
- A composite widget (tabs, listbox, menu, date picker, grid) has one tab stop and arrow-key focus inside, by roving
  `tabindex` (one item `0`, the rest `-1`) or `aria-activedescendant`.
- Expanded, selected, checked, pressed, invalid and busy update their ARIA state or native property with the look.
- Pointer targets are at least 24 × 24 CSS px, or spaced so a 24 px circle around each touches no other; enlarge the
  hit area, not the icon.

## Contrast and colour

- Text 4.5:1 (large text - 24px, or 18.66px bold - 3:1); focus indicators and control boundaries 3:1 against adjacent
  colours, in every state (default, hover, active, focus, visited, disabled).
- Colour is never the only cue for error, success, required or selected: add text or a named icon.
- No alpha (`opacity`, `rgba`, `hsla`) on text or key affordances.

## Forced colours

- The UI adapts by itself. Add `@media (forced-colors: active)` only where system defaults fall short, with system
  colour keywords (`CanvasText`, `ButtonText`, `ButtonBorder`), never fixed colours; don't rely on box shadows or
  gradients there. A `box-shadow` focus ring also sets `outline: 2px solid transparent`, which forced colours shows.
- No `forced-color-adjust: none` unless justified, with an accessible alternative.
- Icons follow the text colour: SVG `fill` / `stroke: currentColor`, no colours baked in.

## Reflow (320 CSS px)

- Nothing essential is lost, hidden or truncated; multi-column layouts stack; collapsed content is one click away.
- No horizontal scrolling for multi-line text: no widths that force it, media `max-width: 100%`, flex children
  `min-width: 0`, long strings `overflow-wrap: anywhere`; avoid `overflow: hidden` or absolute positioning that clips.

## Labels and forms

- Every control has a visible label that stays visible while typing and after a value is set, and a programmatic one
  (prefer `<label for>`). The accessible name contains the visible text (voice control); repeated labels ("Remove")
  get an `aria-label` keeping the text and adding context.
- Help text and errors are linked with `aria-describedby`.
- Required fields: a visual mark and native `required`; `aria-required="true"` only where `required` can't go (a
  custom widget).
- Errors say how to fix the input and set `aria-invalid="true"` until valid. Don't disable submit to block it; on an
  invalid submit, focus the first invalid field.

## Images, navigation, tables

- An informative `<svg>` gets `role="img"` + `aria-label` / `aria-labelledby`; decorative images `alt=""` or
  `aria-hidden="true"`.
- Site navigation is `<nav>` with lists of links, never `role="menu"` / `menubar`. Expandable sections toggle through
  a `<button>` with `aria-expanded`; `Escape` may close them.
- Static tabular data is a `<table>` with `<th>`; `role="grid"` only for truly interactive grids, with arrow-key
  navigation.

## Before you finish

Verify each area the change touches, then recommend a manual assistive-technology check (for example Accessibility
Insights): automated rules catch only part of the problems.
