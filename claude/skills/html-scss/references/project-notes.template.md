# HTML / SCSS project notes

<!-- Facts about this repository that the conventions:html-scss skill relies on. Keep only what was verified in
     the repository; delete a line rather than guess. Rules never go here - only facts. -->

## Modules

| Module | `@use` | Holds |
|---|---|---|
| Design variables | `variables` | colours, spacing, radius, z-index |
| Breakpoints | `breakpoints` | `apply-from-tablet()`, `apply-from-desktop()` |
| Element defaults | `elements` | tag-level defaults (`elements/` partials) |

## Global styles

- Entry point: `src/styles.scss`
- Global partials (routed pages, shared styles): `src/styles/partials/`
- Vendor overrides partial: `<path>`
- Styles shared by several components and defined once globally: `<e.g. dialog-actions, line-button in ...>`
- What the global `button` style already sets: `<properties>`
