---
date: 2026-04-07
title: "ADR-001: ObservableModel — Observation-based reactive state machine"
status: accepted
---

# ADR-001: ObservableModel — Observation-based reactive state machine

## Context

`RxViewModel` in `IMRx` uses Combine (`ObservableObject`, `@Published`, `PassthroughSubject`) and
`CombineSchedulers` for serialized event processing. Porting it to Swift Observation requires
fundamentally different machinery — the result is a new type, not a drop-in replacement.

## Decision

Introduce a **new module `IMRxObservation`** containing `ObservableModel<State, Event, Effect>`.

### Key design choices

| Aspect | `RxViewModel` (IMRx) | `ObservableModel` (IMRxObservation) |
|---|---|---|
| Reactivity | `ObservableObject` / `@Published` | `@Observable` macro |
| Event serialization | `PassthroughSubject` + `receive(on: scheduler)` | `AsyncStream` + `for await` loop in a `Task` |
| Effect handler signature | `(Effect, @escaping (Event) -> Void) -> Void` | `(Effect) -> AsyncStream<Event>` |
| Scheduler control | `CombineSchedulers` (`AnySchedulerOf<DispatchQueue>`) | None — async runtime handles scheduling |
| Test determinism | `.immediate` scheduler | `withMainSerialExecutor` from `swift-concurrency-extras` |
| Sendability | Not `Sendable` | `@unchecked Sendable` |
| Platform minimum | iOS 14 / macOS 11 | iOS 17 / macOS 14 (Observation framework) |

### Why a new module (not replacing `RxViewModel`)

- `@Observable` is not a drop-in for `ObservableObject` — consumers using `@ObservedObject`,
  `@StateObject`, or `$state` (Combine publisher) would break.
- Existing `IMRx` consumers can continue without changes.
- Clean separation avoids conditional compilation and `#if` availability sprawl.

### Why `@unchecked Sendable`

- State writes are serialized through the `AsyncStream` consumer (single `Task`).
- State reads are struct copies (value semantics).
- `ObservationRegistrar` is internally synchronized.
- `AsyncStream.Continuation` is `Sendable`.
- No `@MainActor` isolation — the model is a general-purpose state machine, not tied to UI.

### Why `AsyncStream<Event>` for effect handler

- Supports multi-emit effects (e.g., cache hit followed by network update).
- Natural fit for async/await — no callback-based dispatch.
- Single-event effects simply yield once and finish.

## Consequences

- `IMRxObservation` has no dependency on `IMRx` or Combine.
- Test dependency on `swift-concurrency-extras` for `withMainSerialExecutor`.
- Existing `Reducer` and `EffectHandler` protocols from `IMRx` are not reused — the async
  effect handler signature is incompatible. Closure-based typealiases are used instead.
