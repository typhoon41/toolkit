---
name: angular
description: Angular (20+, zoneless, signals) and TypeScript conventions - components, signals instead of getters, class member style, templates without logic, state, HTTP, forms, shared components, i18n. Apply whenever writing, refactoring or reviewing .ts files or Angular templates.
---

# Angular / TypeScript

Builds on `code-design`; markup and styling rules, including host-element styling, live in `html-scss`.

## Project notes

Repository facts this skill relies on - selector prefix, shared components, path aliases, routing helpers, i18n
command and locale files, exempt areas, pinned packages - live in `.claude/project-notes/angular.md`. Read it
before working. If it is missing and the task needs one of those facts, create it from
`references/project-notes.template.md` (next to this skill) with only what you verified in the repository. A
project fact goes there, never into a copy of this skill.

## Components

```ts
@Component({
    changeDetection: ChangeDetectionStrategy.OnPush,
    selector: '<prefix>-entry-dialog',
    imports: [...],
    templateUrl: './entry-dialog.html',
    styleUrl: './entry-dialog.scss'
})
```

- Standalone and `OnPush`, always. The selector uses the project's prefix.
- Inputs are `input()` / `input.required()`; `model()` only for two-way binding. Never `@Input()`.
- Templates use `@if` / `@for (...; track ...)`, never `*ngIf` / `*ngFor`.
- **No `ChangeDetectorRef`.** The app is zoneless, so a view updates only when a signal it reads changes. Needing
  `detectChanges()` / `markForCheck()` means template state is not a signal yet - make it one. DOM work that needs
  the rendered view goes in `afterNextRender(() => ..., { injector })`.

## Templates render, they don't decide

No ternaries, `&&` / `||`, comparisons or non-null assertions in a binding or interpolation. Bind a `computed()`
or a model member instead. `@if` / `@for` on a boolean signal or a collection is control flow and stays.

```html
<!-- Wrong -->
<app-dialog [title]="editing() ? 'Edit entry' : 'New entry'">
@if (weeklyTotal() > 0) { ... }

<!-- Right -->
<app-dialog [title]="title()">
@if (hasWeeklyTotal()) { ... }
```

## Classes

- **Signals, never getters.** Derived state on any class (component, model, value object) is
  `readonly x: Signal<T> = computed(() => ...)`. Sources stay plain `readonly` fields or `signal()`s; a private
  mutable flag is exposed with `.asReadonly()`. Call sites invoke it - a bare `week.label` is an always-truthy
  Signal object and silently breaks boolean checks.
- **Functions are arrow-function properties**: `readonly name = (...) => ...`, `static readonly` for statics,
  `private` where only the class uses them. The constructor and lifecycle hooks (`ngOnInit`, `ngOnDestroy`, ...)
  are the only method-syntax members; never mix the two styles in one class.
- A helper serving one class is its `private static readonly` member, not a module-level function beside it, and
  never an alias of one (`static toTime = toTime`).
- Member order: statics, state and signals, constructor, functions.
- **Visibility:** never write `public` (it is the default). Members only the template or host bindings use are
  `protected readonly`; members other classes call stay plain `readonly`; the rest are `private`.
- Inject with `inject()`; name the dependency in full (`changeDetector`, `elementReference`).

## State

Signals only, no NgRx:

| Need | Use |
|---|---|
| Mutable state | `signal<T>(initial)` |
| Derived, read-only | `computed(() => ...)` |
| Derived, resettable when its source changes | `linkedSignal({ source, computation })` |
| Side effect | `effect(() => ...)`; one-shot: `{ manualCleanup: true }` and `destroy()` itself |

## HTTP

- Reads that follow signal inputs: `httpResource()`; normalise the wire format in its `parse` function at the
  service boundary.
- Mutations (POST / PUT / DELETE): `lastValueFrom(this.http.post(...))`. Never `subscribe()` for a mutation.

## Forms

- `NonNullableFormBuilder` with `updateOn: 'blur'`.
- A field component receives the parent `FormGroup` through `input()`; it never injects or builds one.
- Dialog actions that share loading, error and dismissal handling share one private function property - or, when
  that carries state, its own abstraction. Every awaited call in an action has a `catch`: `try` / `finally` alone
  leaves an unhandled rejection, an open dialog and no feedback.

## Project building blocks

The concrete names are in the project notes.

- **Shared components first.** Before writing a native `<input>`, `<select>`, `<textarea>`, `<dialog>` or a
  collapsible section, use the shared component that exists for it.
- **Path aliases.** Imports that cross a feature boundary use the `tsconfig` path aliases, never `../../`.
- **Routing.** Navigate through the project's route definitions, never hand-built route strings.
- **i18n.** User-facing strings use `` $localize`:@@key.name:default text` ``. Run the extraction command after
  adding keys and add the translation to every locale file; a removed string is removed from every locale file in
  the same change. Exempt areas use plain strings.
