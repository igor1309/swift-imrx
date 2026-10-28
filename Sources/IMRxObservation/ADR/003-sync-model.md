---
date: 2026-10-28
title: "ADR-003: SyncModel — a state machine that reduces when the event arrives"
status: accepted
---

# ADR-003: SyncModel — a state machine that reduces when the event arrives

## Context

`ObservableModel.event(_:)` yields into an `AsyncStream`; the reduction happens later, when the
model's loop task runs. No read can be ordered after the events already sent: a caller that sends
an event and then reads `state` may see the state from before it.

Audelin's Recording needs exactly that order. Quit must not terminate until every Session that
has begun has ended, so after it sends `userStop` its read of the state must include every event
sent before. With `ObservableModel` that takes a barrier, and a barrier means a queue around the
model or an infrastructure event in the domain.

The work the effect handler does can live outside the machine instead. The state reflects what
the event changed (iOS Flow's `var isLoading: Bool`); a doer observes the state, does the sync or
async work, and feeds the result back through `event`. With the effects outside, the machine
itself has nothing asynchronous left, and it can reduce at once.

### Rejected alternatives

| Alternative | Why not |
|---|---|
| A barrier in front of `ObservableModel` | Events handed to the model are not yet reduced, so the barrier cannot answer "everything before is reduced" without an acknowledgement path. |
| A drain event in the domain | Infrastructure in the domain; every domain that needs the order would carry it. |
| Changing `ObservableModel` to reduce synchronously | Breaks its effect contract and every existing consumer. `ObservableModel` has earned its place, as `RxViewModel` has. |

## Decision

Add `SyncModel<State, Event>` to `IMRxObservation`, beside `ObservableModel`, which does not change.

1. `init(initialState:reduce:predicate:)` with `reduce: (State, Event) -> State`. It starts no
   task, so it takes no `isolation:`; item 4 confines it.
   An `Equatable` convenience `init` uses `==` as the predicate, as `ObservableModel` does.
2. `event(_:)` MUST reduce before it returns. A read of `state` after `event` returns MUST
   reflect that event and every event before it.
3. `SyncModel` MUST NOT run effects, start tasks or hold a stream. Its reducer has no effect output.
4. Like `ObservableModel` (ADR-002), it MUST stay on the actor that makes it: the type is not
   `Sendable`, so the compiler keeps `event(_:)` and `state` in its creator's isolation. Callers on another actor
   `await` the hop, so each caller's events keep its order.
5. `state` MUST be observable. It MUST NOT be assigned when the predicate holds for the old and
   new state.
6. How the state is modelled for a doer is the concrete domain's choice; `SyncModel` imposes none.

## Consequences

- A domain that needs read-after-send order composes `SyncModel` with a reducer and a doer; one
  that needs effects inside the machine keeps `ObservableModel`.
- Unlike `ObservableModel.event(_:)`, `SyncModel.event(_:)` cannot be called from any thread;
  callers off its actor hop with `await`.
- A minor release: 1.1.0. No existing API changes.

## Verification gates

Implementation lands only when tests show:

1. After `event(_:)` returns, `state` is the reduced state, with no `await` between them.
2. Two events in a row reduce in order: the second reducer call receives the first's result.
3. A state equal under the predicate is not assigned: an observer of `state` is not notified.
4. An `Observations` (or `withObservationTracking`) observer sees a change from `event(_:)`.
5. The model releases with no retain cycle (memory-leak tracking as in `ObservableModelTests`).
6. From a model made on the main actor, a caller on another actor can only reach `event(_:)` by `await`
   (a compile-time property; recorded by a test calling it through `await MainActor.run`).
