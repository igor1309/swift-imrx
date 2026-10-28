//
//  SyncModel.swift
//
//
//  Created by Igor Malyarov on 28.10.2026.
//

import Observation

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
@Observable
/// Reduces each event before `event(_:)` returns, so a later read of `state`
/// reflects every event sent before it. It runs no effects: a doer observes
/// `state`, does the work, and sends the result back through `event(_:)`.
/// It is not `Sendable`, so it stays on the actor that made it.
public final class SyncModel<State, Event> {

    public private(set) var state: State

    @ObservationIgnored private let reduce: Reduce
    @ObservationIgnored private let predicate: Predicate

    public init(
        initialState: State,
        reduce: @escaping Reduce,
        predicate: @escaping Predicate
    ) {
        self.state = initialState
        self.reduce = reduce
        self.predicate = predicate
    }

    public func event(_ event: Event) {

        let newState = reduce(state, event)

        if !predicate(state, newState) {
            state = newState
        }
    }
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
public extension SyncModel {

    typealias Reduce = (State, Event) -> State
    typealias Predicate = (State, State) -> Bool
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
public extension SyncModel where State: Equatable {

    convenience init(
        initialState: State,
        reduce: @escaping Reduce
    ) {
        self.init(
            initialState: initialState,
            reduce: reduce,
            predicate: ==
        )
    }
}
