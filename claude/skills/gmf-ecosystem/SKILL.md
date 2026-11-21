---
name: gmf-ecosystem
description: The Gmf .NET ecosystem (Gmf.DDD.Common, Gmf.Net.Core.Common, Gmf.Mail.Common) - unit of work, domain and integration events, conflict exceptions, enumerations, entities and value objects, Autofac registration, email. Apply when writing or reviewing C# in a solution that references any Gmf.* package.
---

# Gmf ecosystem

Builds on `dotnet`: these packages are the concrete types behind its generic rules.

| `dotnet` rule | Gmf type |
|---|---|
| The unit of work commits once per request | `TransactionFilter` |
| A broken invariant becomes `409 Conflict` through one filter | `DomainConflictException`, `DomainConflictFilter` |
| A fixed set of persisted values is an enumeration class | `Enumeration<T>` |
| Side effects are dispatched only after a successful commit | `IStoreEvents`, `BaseDbContext` |

## Unit of work

`TransactionFilter` (Gmf.Net.Core.Common) wraps every controller action and calls `SaveChangesAsync()` once it returns
2xx with a valid model state; when the action throws, nothing is saved.

## Events

- **Domain events:** `EntityDto.AddDomainEvent(...)` inside repository methods; `BaseDbContext.SaveChangesAsync`
  dispatches them. Never dispatch from a controller or service.
- **Integration events** (emails, notifications): `IStoreEvents.Add(...)`; `BaseDbContext` publishes them after
  `base.SaveChangesAsync`, so only on a successful commit.

## Domain rules

- A broken invariant throws a `DomainConflictException` subclass (`Gmf.DDD.Common.Concepts`); `DomainConflictFilter`
  answers 409 and `TransactionFilter` saves nothing.
- A fixed set of persisted values derives from `Enumeration<T>`.
- Entities derive from `Entity<T>`, value objects from `ValueObject`; a time range is a `Period`.

## Registration (Autofac)

In the project's Autofac modules, never in `Program.cs`:

| New | Registration | Module |
|---|---|---|
| Repository | `DefaultInterfaceRegistration<TRepository>()` | repository module |
| Service | `DefaultInterfaceRegistration<TService>()` | service module |
| Settings section | `SingleSelfRegistration<TSettings>()` | configuration module |

## Email

Send through Gmf.Mail.Common's `IEmailClient` from an integration event's handler; `EmailClientStub` stands in where
no SMTP server is configured.
