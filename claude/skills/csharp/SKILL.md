---
name: csharp
description: C# and ASP.NET Core conventions - no Async suffix, thin controllers, validation, domain models instead of enums, repositories and queries, side effects after commit, logging, security. Apply whenever writing, refactoring or reviewing any .cs file.
---

# C# / ASP.NET Core

In a solution referencing `Gmf.*` packages, `gmf-packages` names the concrete types.

## No `Async` suffix

A `Task` / `ValueTask` method has no `Async` suffix, except where an override or implemented framework member fixes
the name (`SaveChangesAsync`, `ExecuteAsync`, filter `On…Async`, `Handle…Async`, `InvokeAsync`, `StartAsync` /
`StopAsync`, `DisposeAsync`, `BindModelAsync`, ...).

## Thin controllers

An action binds, calls one service method and maps the result to a status code. Mapping, date arithmetic, change
detection, notification decisions and orchestration live in a service behind an interface in the domain's service
contracts. Request-to-domain mapping is `ToDomain()` on the request model.

```csharp
public async Task<IActionResult> UpdateEntry(Guid id, EntryRequest request) =>
    await calendarService.UpdateEntry(id, request.ToDomain(id)) ? NoContent() : NotFound();
```

Every action declares `[ProducesResponseType]` for each status it returns, including `400` with
`ValidationProblemDetails`.

## Validation

- Every request model carrying user input has a FluentValidation validator.
- Never bind a domain model or persistence record from a request (mass assignment): bind a request model with explicit
  fields and map it with `ToDomain()`.
- A size limit is a `const` on the model, used by the validator and the EF `HasMaxLength` alike.
- A uniqueness rule excludes the record being edited (`existing.Id != request.Id`).
- A rule needing the database uses `MustAsync`, never a blocking query in `Must`.

## Nullability

No null-forgiving `!`: fix the cause of the warning.

## Domain models

- Rules live on models in `Domain/Models/` with private setters: state changes only through a factory and named
  methods that enforce the rules.
- The controller maps found / not found with `? NoContent() : NotFound()`.
- A broken invariant is an exception in `Domain/Exceptions/`, turned into `409 Conflict` by one filter.
- A fixed set of persisted values is an enumeration class with named static instances (it can carry behaviour) in
  `Domain/Enumerations/`.

## Repositories and persistence

- Two contracts per aggregate: `I{Aggregate}RetrievalRepository` (queries) and `I{Aggregate}ModificationRepository`
  (writes); never mixed.
- Repositories add and modify entities on the `DbContext` and never call `SaveChangesAsync`: the unit of work commits
  once per request.
- Persistence records own their mapping: `static MapFrom(domain)` and `MapTo{Model}()`; no mapping frameworks.
- Read queries project with `Select` into what they return.
- A reusable query filter is one `IQueryable<T>` extension, where a `null` / empty argument means "no filter".
- Pass the request's `CancellationToken` to every EF and I/O call.
- A schema change ships with its migration.

## Side effects after commit

Never send an email, message or other outward effect from an action or service call: raise an integration or domain
event dispatched only after a successful `SaveChangesAsync`.

## Culture-aware output

Never hard-code a date or time format: set the recipient's culture, then format with `CultureInfo.CurrentCulture`
(`"d"`, `"t"`).

## Logging

Injected `ILogger<T>`, message templates with named placeholders (`"Saved entry {EntryId}"`), never interpolation;
never secrets, tokens or personal data.

## Security

- Endpoints require authorisation by default; anonymous access is explicit. Loading by id also checks the caller may
  access that object.
- A response model carries only the fields the client uses; no sensitive data in query strings (URLs are logged).
- Raw SQL only through parameterised `FromSql` / `ExecuteSql`, never interpolated into `FromSqlRaw` / `ExecuteSqlRaw`.
- Exception details never reach a response (generic `ProblemDetails`); Swagger / OpenAPI only in Development.

## Determinism and build

- Inject `TimeProvider`; never read `DateTime.Now` / `UtcNow`.
- Package versions only in `Directory.Packages.props`; a `PackageReference` never carries `Version`.
- A change adds no compiler or analyzer warnings.
