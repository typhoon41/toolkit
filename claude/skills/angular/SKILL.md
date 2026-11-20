---
name: angular
description: Angular (20+, zoneless, signals) conventions - components, signal APIs, no lifecycle hooks, computed derived state, logic-free templates, host-class styling, state, HTTP, errors, forms, routing, i18n. Apply whenever writing, refactoring or reviewing code or templates in an Angular project.
---

# Angular

## Components

- `changeDetection: ChangeDetectionStrategy.OnPush` always; never `standalone: true` (the default); the selector uses
  the project's prefix.
- Signal APIs only: `input()` / `input.required()`, `model()` only for two-way binding, `output()`, `viewChild` /
  `viewChildren` / `contentChild` queried by type (`viewChild.required(EntryList)`), never by a reference string.
  Never the `@Input` / `@Output` / `@ViewChild` decorators.
- `inject()` only in field initialisers; the constructor only registers `effect()`s.
- **No `ChangeDetectorRef`** (zoneless): needing `detectChanges()` / `markForCheck()` means template state is not a
  signal yet - make it one. DOM work needing the rendered view: `afterNextRender(() => ..., { injector })`.
- **No lifecycle hooks** - no `ng*` hook method and no `implements OnInit, ...`:

  | Instead of | Use |
  |---|---|
  | `ngOnChanges`, deriving from inputs | `computed()` over the input signals |
  | `ngOnInit`, reacting to inputs or starting work | an `effect()` registered in the constructor, or `httpResource()` for data |
  | `ngAfterViewInit`, DOM after render | `viewChild()` + `afterNextRender(() => ..., { injector })` |
  | `ngOnDestroy`, teardown | `inject(DestroyRef).onDestroy(...)` or `takeUntilDestroyed()` |

## Signals

- **Derived state is `computed()`** on every class - component, model, value object:
  `readonly x: Signal<T> = computed(() => ...)`. Sources stay plain `readonly` fields or `signal()`s; a private
  mutable one is exposed with `.asReadonly()`.
- Call sites invoke it: a bare `week.label` is an always-truthy Signal and silently breaks boolean checks.
- Members only the template or host bindings use are `protected readonly`; members other classes call are `readonly`.

## Templates render, they don't decide

- A binding or interpolation reads signals and model members only: no ternaries, `&&` / `||`, comparisons, `!` or
  calls into component functions (they run on every check). Bind a `computed()` or a model member instead.

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

- `@if` / `@for` / `@switch` on a boolean signal or a collection; `@empty` for the empty state; `@defer` for heavy,
  below-the-fold content.
- **`@for` tracks a stable identity**: the domain id, else a unique primitive, else `$index`. Never `track item`
  (identity changes whenever the array is rebuilt). With `$index`, a child keeping per-item state resets it when its
  input changes.

## Component styling

- **The host element replaces wrappers**: `host: { class: 'calendar-grid-container' }` in the decorator.
- Style a host class in the stylesheet of the **component whose template renders it** - the host carries that
  parent's encapsulation attribute and stays in its lazy bundle. A routed page is styled in the global partials.
  Never in the component's own stylesheet, never `:host`.
- When markup moves to another component, every rule styling it moves too: encapsulation silently stops the old rule
  matching.
- No `[style.x]`, `[style.--custom]` or `[ngStyle]`: bind classes the model computes
  (`[class]="entry.placementClasses()"`, `[class.selected]="entry.selected()"`).
- Never `::ng-deep`; `ViewEncapsulation.None` only with a comment giving the reason.
- Deep nesting: extract a child component.

## State

Signals only, no NgRx:

| Need | Use |
|---|---|
| Mutable state | `signal<T>(initial)` |
| Derived, read-only | `computed(() => ...)` |
| Derived, resettable when its source changes | `linkedSignal({ source, computation })` |
| A stream a template reads | `toSignal(observable, { initialValue })` (`requireSync` for synchronous sources) |
| Side effect leaving Angular (storage, a third-party widget) | `effect(() => ...)`; never to derive state |

## HTTP

- Reads following signal inputs: `httpResource()`, normalising the wire format in its `parse` function.
- Any other `HttpClient` call is a one-value source and is awaited; a real stream tears down with
  `takeUntilDestroyed()`.

## Errors

- Catch an awaited call **only where the user can act on the failure**: a dialog action stays open and shows what
  failed. Elsewhere let it propagate - the global HTTP interceptor reports it; never a second notification.
- Server validation errors go onto the form fields, not a toast.
- `console.error` only for failures with no UI to report them.
- Dialog actions sharing loading, error and dismissal handling share one private function property - or their own
  abstraction when that carries state.

## Forms

- `NonNullableFormBuilder` with `updateOn: 'blur'`; typed controls (`FormControl<string>`).
- A field component receives the parent `FormGroup` through `input()`; it never injects or builds one.
- Custom validators live in one shared place, not in components.

## Project building blocks

Concrete names are in the project's `CLAUDE.md`.

- **Shared components first** for `<input>`, `<select>`, `<textarea>`, `<dialog>` and collapsible sections.
- Navigate through the route definitions, never hand-built route strings.
- **i18n**: `` $localize`:@@key.name:default text` `` - the `@@` id is mandatory (a generated id breaks when the
  wording changes). Reuse shared keys (OK, Cancel, Save, ...) before adding one; one key per concept. After adding
  keys run the extraction command and translate in every locale file; a removed string leaves every locale file in
  the same change. Exempt areas use plain strings.
