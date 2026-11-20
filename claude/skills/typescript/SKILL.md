---
name: typescript
description: Framework-independent TypeScript conventions - class member style (arrow-function properties, no getters, no public), typing without any or non-null assertions, async/await instead of subscriptions and then-chains, module imports. Apply whenever writing, refactoring or reviewing .ts files, in any project.
---

# TypeScript

Builds on `code-design`. A framework skill (for example `angular`) adds its own rules on top and never restates
these.

## Classes

- **Every function is an arrow-function property**: `readonly name = (...) => ...`, `static readonly` for statics,
  `private` where only the class uses it. The constructor is the only member written with method syntax; never
  mix the two styles.
- An arrow property is declared before any field initialiser that calls it (initialisers run in order); tests spy
  on the instance, not the prototype.
- A helper serving one class is its `private static readonly` member, not a module-level function beside it, and
  never an alias of one (`static toTime = toTime`).
- Member order: statics, state, constructor, functions.
- **No `get` accessors.** A derived value is a `readonly` member, or the framework's reactive primitive where the
  framework skill names one.
- Never write `public`: it is the default. Members only the class uses are `private`.

## Types

- No `any`: use `unknown` and narrow it. A cast is a last resort; never `as any`.
- No non-null assertion `!`: handle the absent case.
- No `I` prefix on interfaces, no leading `_` on names.
- Check presence by truthiness; compare explicitly only when a falsy value (`0`, `''`, `false`) is valid.

## Asynchronous code

- **`async` / `await`, always.** Never `.then()` / `.catch()` chains, and never a Promise left floating or
  discarded with `void`. The one exception is a lazy `import()` that picks a single export, written on one line:
  `import('./page').then(module => module.Page)`, the module-loading idiom bundlers and routers expect.
- **Subscribe only to a real stream** - a source that keeps emitting values over time (events, a WebSocket, a
  store) - and always tear the subscription down.
- A source that delivers one value (an HTTP call, a single lookup) is turned into a Promise and awaited, never
  subscribed to. With RxJS - a library, used with or without a framework - that is
  `await firstValueFrom(source)` / `await lastValueFrom(source)`.

## Modules

Imports that cross a feature boundary use the `tsconfig` path aliases, never `../../`.
