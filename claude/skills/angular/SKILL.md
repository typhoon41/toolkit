---
name: angular
description: Angular (20+, zoneless, signals) and TypeScript conventions - components, signal APIs, class member style, templates without logic, @for tracking, state, RxJS, HTTP, forms, errors, shared components, i18n, TypeScript typing. Apply whenever writing, refactoring or reviewing .ts files or Angular templates.
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

- `OnPush` always. Standalone is the default: never write `standalone: true`. The selector uses the project's
  prefix.
- Signal APIs only: `input()` / `input.required()`, `model()` only for two-way binding, `output()`,
  `viewChild` / `viewChildren` / `contentChild`, queried by type (`viewChild.required(EntryList)`), never by a
  template-reference string. Never the `@Input` / `@Output` / `@ViewChild` decorators.
- `inject()` only in field initialisers; the constructor only registers `effect()`s.
- **No `ChangeDetectorRef`.** The app is zoneless, so a view updates only when a signal it reads changes. Needing
  `detectChanges()` / `markForCheck()` means template state is not a signal yet - make it one. DOM work that needs
  the rendered view goes in `afterNextRender(() => ..., { injector })`.
- Prefer signals to lifecycle hooks: `ngOnChanges` → `computed()`, `ngOnDestroy` → `DestroyRef.onDestroy` /
  `takeUntilDestroyed()`, `ngAfterViewInit` → `viewChild` + `afterNextRender`. A hook is never `async`, and no
  Promise is left floating in a hook or the constructor.

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

## Classes

- **Signals, never getters.** Derived state on any class (component, model, value object) is
  `readonly x: Signal<T> = computed(() => ...)`. Sources stay plain `readonly` fields or `signal()`s; a private
  mutable flag is exposed with `.asReadonly()`. Call sites invoke it - a bare `week.label` is an always-truthy
  Signal object and silently breaks boolean checks.
- **Functions are arrow-function properties**: `readonly name = (...) => ...`, `static readonly` for statics,
  `private` where only the class uses them. The constructor and lifecycle hooks are the only method-syntax members;
  never mix the two styles in one class. An arrow property is declared before any field initialiser that calls it
  (initialisers run in order), and tests spy on the instance, not the prototype.
- A helper serving one class is its `private static readonly` member, not a module-level function beside it, and
  never an alias of one (`static toTime = toTime`).
- Member order: statics, state and signals, constructor, functions.
- **Visibility:** never write `public` (it is the default). Members only the template or host bindings use are
  `protected readonly`; members other classes call stay plain `readonly`; the rest are `private`.
- Name injected dependencies in full (`changeDetector`, `elementReference`).

## TypeScript

- No `any`: use `unknown` and narrow it. A cast is a last resort; never `as any`.
- No non-null `!` anywhere; handle the absent case.
- No `I` prefix on interfaces, no leading `_` on names.
- `async` / `await` over `.then()` chains; never discard a Promise with `void`.
- Check presence by truthiness; compare explicitly only when a falsy value (`0`, `''`, `false`) is valid.

## State

Signals only, no NgRx:

| Need | Use |
|---|---|
| Mutable state | `signal<T>(initial)` |
| Derived, read-only | `computed(() => ...)` |
| Derived, resettable when its source changes | `linkedSignal({ source, computation })` |
| Observable a template reads | `toSignal(observable, { initialValue })` (`requireSync` for synchronous sources) |
| Side effect leaving Angular (storage, a third-party widget) | `effect(() => ...)`; never to derive state |

## RxJS and HTTP

- Reads that follow signal inputs: `httpResource()`; normalise the wire format in its `parse` function at the
  service boundary.
- One-shot Observables (every HTTP call outside `httpResource`): `await lastValueFrom(...)` /
  `firstValueFrom(...)`. `subscribe()` only for real streams, always with `takeUntilDestroyed()`.

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

The concrete names are in the project notes.

- **Shared components first.** Before writing a native `<input>`, `<select>`, `<textarea>`, `<dialog>` or a
  collapsible section, use the shared component that exists for it.
- **Path aliases.** Imports that cross a feature boundary use the `tsconfig` path aliases, never `../../`.
- **Routing.** Navigate through the project's route definitions, never hand-built route strings.
- **i18n.** User-facing strings use `` $localize`:@@key.name:default text` `` - the `@@` id is mandatory, since a
  generated id breaks whenever the wording changes. Reuse the shared keys (OK, Cancel, Save, ...) before adding
  one; one key per concept. Run the extraction command after adding keys and add the translation to every locale
  file; a removed string is removed from every locale file in the same change. Exempt areas use plain strings.
