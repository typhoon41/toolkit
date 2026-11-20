---
name: typescript
description: Framework-independent TypeScript conventions - arrow-function members, no getters or public, typing without any or non-null assertions, async/await instead of subscriptions and then-chains, one abstraction per module. Apply whenever writing, refactoring or reviewing .ts files, in any project.
---

# TypeScript

## Classes

- **Every function is an arrow-function property** (`readonly name = (...) => ...`, `static readonly` for statics);
  only the constructor uses method syntax.
- Declare an arrow property before any field initialiser that calls it; tests spy on the instance, not the prototype.
- A helper serving one class is its `private static readonly` member - not a module-level function beside it, nor an
  alias of one (`static toTime = toTime`).
- Member order: statics, state, constructor, functions.
- **No `get` accessors**: a derived value is a `readonly` member, or the framework's reactive primitive.
- Never write `public`; members only the class uses are `private`.

## Types

- No `any` (use `unknown` and narrow; a cast is a last resort, never `as any`). No non-null `!`: handle the absent case.
- No `I` prefix on interfaces, no leading `_`.
- Check presence by truthiness; compare explicitly only when `0`, `''` or `false` is valid.

## Asynchronous code

- **`async` / `await` only**: no `.then()` / `.catch()` chains, no floating or `void`-discarded Promise. Sole
  exception: a one-line lazy import picking one export, `import('./page').then(module => module.Page)`.
- Subscribe only to a real stream (events, a WebSocket, a store), and always tear it down.
- A one-value source (an HTTP call, a single lookup) is awaited, never subscribed to: with RxJS,
  `await firstValueFrom(source)` / `await lastValueFrom(source)`.

## Modules

- **No `export const` sacks.** Functions sharing a subject become one class named after it (members `static readonly`
  when stateless) - the preferred shape; a function with no such subject gets its own file named after it; a constant
  is a `static readonly` on the class owning its concept.

  ```ts
  // Wrong - date-formatting.ts
  export const shortDateFormat = 'd.M.';
  export const toIsoDate = (date: Date) => ...;

  // Right - calendar-date.ts
  export class CalendarDate {
      static readonly shortFormat = 'd.M.';
      static readonly fromIso = (iso: string): CalendarDate => ...;
      readonly toIso = (): string => ...;
  }
  ```

- Cross-feature imports use the `tsconfig` path aliases, never `../../`.
