---
date: 2026-10-28
title: "ADR-002: ObservableModel runs on the actor that makes it"
status: accepted
---

# ADR-002: ObservableModel runs on the actor that makes it

## Context

`ObservableModel` was `@unchecked Sendable` with a non-isolated `init`. Its event loop ran on
the global executor, so `state` changed off the main thread while SwiftUI read it on the main
thread: a data race the `@unchecked` hid. Binding the model to `@MainActor` would fix the race
but rule out state machines that are not UI.

## Decision

- `init` takes `isolation: isolated (any Actor)? = #isolation`, and the event loop captures it,
  so the model reduces on the actor that made it: the main actor for a UI model, an owning
  actor for any other.
- The model is not `Sendable`, so the compiler keeps it on that actor.
- `Event` is `Sendable`: `event(_:)` may be called from anywhere, and effect results cross
  into the loop.
- `IMRxObservation` builds in the Swift 6 language mode, so these rules are checked.

## Consequences

- Breaking: `Event` must be `Sendable`, and the model can no longer be passed between actors.
- Package tools version 6.0; a Swift 6 compiler is required. Other targets stay in Swift 5 mode.
- A model made from code with no actor runs on the global executor; it is still confined to
  its creator, but SwiftUI must not observe it.
- First tagged release: 1.0.0.
