---
name: csharp
description: C# and ASP.NET Core conventions - async naming, thin controllers, validation, nullability, rich domain models instead of enums, repositories and queries, side effects after commit, logging, security. Apply whenever writing, refactoring or reviewing any .cs file.
---

# C# / ASP.NET Core

Builds on `code-design` (names, files, braces, models), which is not repeated here. Where the solution references
the Gmf packages, `gmf-packages` names the concrete types.

## Project notes

Repository facts this skill relies on - where models, contracts, services, repositories and DI modules live,
validation message language, how a recipient's culture is set, wire formats - live in
`.claude/project-notes/csharp.md`. Read it before working. If it is missing and the task needs one of those facts,
create it from `references/project-notes.template.md` (next to this skill) with only what you verified in the
repository. A project fact goes there, never into a copy of this skill.

## No `Async` suffix

A method returning `Task` / `Task<T>` / `ValueTask` has no `Async` suffix; the return type says it. Keep the suffix
only where a base type or framework interface you implement fixes the name: overrides (EF Core
`SaveChangesAsync`, `BackgroundService.ExecuteAsync`, ...), MVC filter `On…Async` callbacks
(`OnActionExecutionAsync`, `OnAuthorizationAsync`, `OnExceptionAsync`, ...), authorization handler
`Handle…Async`, middleware `InvokeAsync`, `IHostedService` `StartAsync` / `StopAsync`,
`IAsyncDisposable.DisposeAsync`, `IModelBinder.BindModelAsync`.

## Thin controllers

An action binds the request, calls one service method and maps the result to a status code. Mapping helpers,
date arithmetic, change detection, notification decisions and multi-step orchestration belong in a service behind
an interface in the domain's service contracts. Request-to-domain mapping is a `ToDomain()` method on the request
model.

```csharp
// Wrong - the controller decides, maps and notifies
var existing = await repository.GetEntry(id);
if (existing is null) { return NotFound(); }
await repository.UpdateEntry(id, MapToDomain(id, request));
if (existing.Date != request.Date) { await SendRescheduleEmail(existing, request); }
return NoContent();

// Right
public async Task<IActionResult> UpdateEntry(Guid id, EntryRequest request) =>
    await calendarService.UpdateEntry(id, request.ToDomain(id)) ? NoContent() : NotFound();
```

Every action declares `[ProducesResponseType]` for each status it can return, including `400` with
`ValidationProblemDetails`.

## Validation

- Every request model that carries user input has a FluentValidation validator; a missing one is fixed by writing
  the validator.
- Never bind a domain model or persistence record from a request: bind a request model with explicit fields and
  map it with `ToDomain()` (no mass assignment).
- A size limit is a `const` on the model, referenced by the validator and the EF configuration (`HasMaxLength`)
  alike.
- A uniqueness rule excludes the record being edited (`existing.Id != request.Id`).
- A rule that needs the database is asynchronous (`MustAsync`), never a blocking query inside `Must`.

## Nullability

- No null-forgiving `!`: fix the cause of the warning.
- Check for `null` only where data enters (actions, message consumers, deserialisation); inside, trust the
  nullable annotations.

## Models instead of enums

How `code-design`'s no-enum rule looks in C#:

- The rule lives on a domain model in `Domain/Models/`, which answers or refuses; the service only orchestrates.
- Found / not found is `bool` or a nullable return; the controller maps it with `? NoContent() : NotFound()`.
- A broken invariant is a domain exception in `Domain/Exceptions/`, translated to `409 Conflict` by one filter.
- A fixed set of persisted values is an enumeration class with named static instances (it can carry behaviour)
  in `Domain/Enumerations/`.
- Domain models have private setters: state changes only through a factory and named methods that enforce the
  rules.

```csharp
// Wrong - an outcome enum, the rule in the service, a switch to read it back
public enum SaveOutcome { Saved, NotFound, Overlapping }

// Right - the model owns the rule and refuses by throwing
var booking = new CalendarBooking(entry, existing);
booking.Claim(booking.ClaimsSlot && await repository.IsOccupied(booking));
```

## Repositories and persistence

- Each aggregate has two repository contracts: `I{Aggregate}RetrievalRepository` (queries) and
  `I{Aggregate}ModificationRepository` (writes). Never mix reads and writes in one interface.
- Repositories add and modify entities on the `DbContext`; the unit of work commits once per request, so they
  never call `SaveChangesAsync`.
- Persistence records own their mapping: `static MapFrom(domain)` builds the record, `MapTo{Model}()` returns the
  domain model. No mapping frameworks.
- Read queries project with `Select` into what they return instead of loading whole entities.
- A reusable query filter is an `IQueryable<T>` extension, one per filter, where a `null` / empty argument means
  "no filter".
- Pass the request's `CancellationToken` to every EF and I/O call.
- A schema change ships with its migration in the same change.

## Side effects after commit

Never send an email, message or other outward effect from inside an action or service call: it would go out even
if the commit fails. Raise an integration or domain event that is dispatched only after a successful
`SaveChangesAsync`.

## Culture-aware output

Never hard-code a date or time format. Set the recipient's culture first, then format with
`CultureInfo.CurrentCulture` (`"d"`, `"t"`), so dates and resource strings render in their language.

## Logging

- Inject `ILogger<T>`; never a static logger.
- Message templates with named placeholders (`"Saved entry {EntryId}"`), never string interpolation.
- Never log secrets, tokens, passwords or personal data.

## Security

- Exception details and stack traces never reach a response: log them and return a generic `ProblemDetails`.
- No secrets or connection strings in code or committed `appsettings`; use user secrets locally and a vault in
  deployed environments.
- Raw SQL only through parameterised `FromSql` / `ExecuteSql`; never concatenated or interpolated into
  `FromSqlRaw` / `ExecuteSqlRaw`.
- Endpoints require authorisation by default; anonymous access is an explicit, visible exception. Loading by id
  also checks that the caller may access that object.
- A response model carries only the fields the client uses.
- No sensitive data in query strings: URLs are logged.
- Swagger / OpenAPI is exposed only in Development.

## Determinism and build

- Never read `DateTime.Now` / `UtcNow` directly: inject `TimeProvider`.
- `nameof()` wherever a string names a member.
- Package versions live only in `Directory.Packages.props`; a `PackageReference` never carries `Version`.
- A change adds no compiler or analyzer warnings.
