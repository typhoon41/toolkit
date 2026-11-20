---
name: angular
description: Angular (20+, zoneless, signals) conventions - components, signal APIs, signals instead of getters, templates without logic, @for tracking, state, HTTP, forms, errors, shared components, routing, i18n. Apply whenever writing, refactoring or reviewing code or templates in an Angular project.
---

# Angular

Builds on `typescript` (class style, typing, async code) and `code-design`; neither is restated here. Markup and
SCSS rules that hold without Angular live in `html-scss`.

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

- `OnPush` always. Standalone is the default: never write `standalone: true`. The selector uses the project's
  prefix.
- Signal APIs only: `input()` / `input.required()`, `model()` only for two-way binding, `output()`,
  `viewChild` / `viewChildren` / `contentChild`, queried by type (`viewChild.required(EntryList)`), never by a
  template-reference string. Never the `@Input` / `@Output` / `@ViewChild` decorators.
- `inject()` only in field initialisers; the constructor only registers `effect()`s. Name the dependency in full
  (`elementReference`).
- **No `ChangeDetectorRef`.** The app is zoneless, so a view updates only when a signal it reads changes. Needing
  `detectChanges()` / `markForCheck()` means template state is not a signal yet - make it one. DOM work that needs
  the rendered view goes in `afterNextRender(() => ..., { injector })`.
- Prefer signals to lifecycle hooks: `ngOnChanges` → `computed()`, `ngOnDestroy` → `DestroyRef.onDestroy` /
  `takeUntilDestroyed()`, `ngAfterViewInit` → `viewChild` + `afterNextRender`. A hook is never `async`, and no
  Promise is left floating in a hook or the constructor.

## Signals

- **Derived state is a signal, never a getter**: `readonly x: Signal<T> = computed(() => ...)` on every class -
  component, model, value object. Sources stay plain `readonly` fields or `signal()`s; a private mutable flag is
  exposed with `.asReadonly()`.
- Call sites invoke it: a bare `week.label` is an always-truthy Signal object and silently breaks boolean checks.
- Members only the template or host bindings use are `protected readonly`; members other classes call stay plain
  `readonly`.

## Templates render, they don't decide

- No ternaries, `&&` / `||`, comparisons or non-null assertions in a binding or interpolation.
- **No calls into component functions**: a template reads signals and model members only. A called function runs
  on every check and hides logic in the view.
- Bind a `computed()` on the component, or a member of the model being rendered, instead.

```html
<!-- Wrong -->
<app-dialog [title]="editing() ? 'Edit entry' : 'New entry'">
@if (weeklyTotal() > 0) { ... }
<span>{{ formatRange(entry) }}</span>

<!-- Right -->
<app-dialog [title]="title()">
@if (hasWeeklyTotal()) { ... }
<span>{{ entry.range() }}</span>
```

- Control flow: `@if` / `@for` / `@switch` on a boolean signal or a collection; `@empty` for the empty state;
  `@defer` for heavy, below-the-fold content.
- **`@for` tracks a stable identity**: the domain id, else a unique primitive, else `$index`. Never `track item`
  (object identity changes whenever the array is rebuilt). With `$index`, a child that keeps per-item state must
  reset it when its input changes.

## State

Signals only, no NgRx:

| Need | Use |
|---|---|
| Mutable state | `signal<T>(initial)` |
| Derived, read-only | `computed(() => ...)` |
| Derived, resettable when its source changes | `linkedSignal({ source, computation })` |
| A stream a template reads | `toSignal(observable, { initialValue })` (`requireSync` for synchronous sources) |
| Side effect leaving Angular (storage, a third-party widget) | `effect(() => ...)`; never to derive state |

## HTTP and streams

- Reads that follow signal inputs: `httpResource()`; normalise the wire format in its `parse` function at the
  service boundary.
- Every other HTTP call is awaited: `await lastValueFrom(this.http.post(...))`.
- A real stream is subscribed with `takeUntilDestroyed()` as its teardown.

## Errors

- Catch an awaited call **only where the user can act on the failure**: a dialog action keeps the dialog open and
  shows what failed. Elsewhere let it propagate; the global HTTP interceptor reports HTTP failures, so features
  never add a second notification.
- Server validation errors go back onto the form fields, not into a toast.
- `console.error` only for failures with no UI to report them.
- Dialog actions that share loading, error and dismissal handling share one private function property - or, when
  that carries state, its own abstraction.

## Forms

- `NonNullableFormBuilder` with `updateOn: 'blur'`; controls are typed (`FormControl<string>`).
- A field component receives the parent `FormGroup` through `input()`; it never injects or builds one.
- Custom validators live in one shared place, not inside components.

## Project building blocks

The concrete names are in the project's `CLAUDE.md`.

- **Shared components first.** Before writing a native `<input>`, `<select>`, `<textarea>`, `<dialog>` or a
  collapsible section, use the shared component that exists for it.
- **Routing.** Navigate through the project's route definitions, never hand-built route strings.
- **i18n.** User-facing strings use `` $localize`:@@key.name:default text` `` - the `@@` id is mandatory, since a
  generated id breaks whenever the wording changes. Reuse the shared keys (OK, Cancel, Save, ...) before adding
  one; one key per concept. Run the extraction command after adding keys and add the translation to every locale
  file; a removed string is removed from every locale file in the same change. Exempt areas use plain strings.
