# Angular project notes

<!-- Facts about this repository that the conventions:angular skill relies on. Keep only what was verified in the
     repository; delete a line rather than guess. Rules never go here - only facts. -->

## Components

- Selector prefix: `<prefix>-`
- Shared component folder: `src/app/shared/components/`

| Need | Shared component |
|---|---|
| Text / number / textarea input | `<prefix>-input` |
| Date picker | |
| Combobox / autocomplete | |
| Checkbox | |
| Modal dialog | |
| Collapsible section | |

## Imports and routing

| Alias | Resolves to |
|---|---|
| `@shared/...` | `src/app/shared/...` |

- Route definitions: `<file or folder>`, helper `<name>`; navigation goes through `<type>`.
- Routes protected automatically: `<rule, e.g. paths starting with admin>`

## i18n

- Default language of `$localize` strings: `<language>`
- Extraction command: `npm run <script>`
- Locale files: `<paths>`
- Exempt areas (plain strings, no `$localize`): `<folders>`

## Pinned dependencies

- `<package>@<version>` - `<why it must not be upgraded>`
