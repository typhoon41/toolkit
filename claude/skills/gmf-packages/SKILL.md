---
name: gmf-packages
description: How to use the Gmf.DDD.Common, Gmf.Net.Core.Common and Gmf.Mail.Common packages - unit of work, domain and integration events, conflict exceptions, enumerations, Autofac registration, email. Apply when writing or reviewing C# in a solution that references any Gmf.* package.
---

# Gmf packages

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
