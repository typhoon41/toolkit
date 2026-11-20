---
name: scss-solutions
description: Using the scss-solutions library - its global utility classes (layout, columns, typography), positioning and breakpoint mixins. Apply when writing or reviewing templates or SCSS in a project whose package.json depends on @typhoon41/scss-solutions.
---

# scss-solutions

Use the library's utility classes and mixins; never re-implement them. The installed package is the authority: before
writing a mixin, function or utility class, list what `node_modules/@typhoon41/scss-solutions/src` exports. When
something is almost right, extend the library (with a test there) instead of forking it into the app.

## Utility classes - applied in HTML only

| Class | Produces |
|---|---|
| `aligned-centrally` | `display: flex; align-items: center` |
| `center-content` | `aligned-centrally` + `::before` / `::after { margin: auto }` |
| `vertical-stack` | `flex-direction: column` |
| `stretch-between` / `stretch-equally` | `justify-content: space-between` / `space-evenly` |
| `stretch` | `width: 100%; height: 100%` |
| `row` | `display: flex; flex-wrap: wrap` - the column container |
| `column-N`, `column-tablet-N`, `column-desktop-N` | `N/12` of the row's width, per breakpoint |
| `offset-N` | `margin-left: N/12` |
| `grow-nested-block` | `flex: 1 1 0; overflow-wrap: break-word` |
| `ellipsis` | single line with `text-overflow: ellipsis` |
| `clickable` | `cursor: pointer` |

- Apply the class in HTML instead of writing its properties in SCSS.
- **Never use one as a selector** in app SCSS (`.notes .column-12 { }`) - it breaks when the markup changes width.
  Style a semantic class beside it:

```html
<div class="field-container column-12">...</div>
```

```scss
.notes-input .field-container { flex: 1 1 auto; }
```

## Mixins

- Absolute positioning always goes through the position module, arguments in `top, right, bottom, left` order,
  `unset` by default:

```scss
@use 'scss-solutions/src/modules/position/absolute';

@include absolute.unset-position(100%, 0, unset, 0);   // not position: absolute; top: 100%; right: 0; left: 0;
@include absolute.zero-position();                    // all four edges at 0
```

- Responsive rules use the project's breakpoint module built on the library
  (`@include breakpoints.apply-from-tablet()` / `apply-from-desktop()`).
