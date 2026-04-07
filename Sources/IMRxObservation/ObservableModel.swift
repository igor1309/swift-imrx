//
//  ObservableModel.swift
//
//
//  Created by Igor Malyarov on 07.04.2026.
//

import Observation

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
@Observable
public final class ObservableModel<State, Event, Effect>: @unchecked Sendable {

    public private(set) var state: State

    private let reduce: Reduce
    private let handleEffect: HandleEffect
    private let predicate: Predicate
    private let continuation: AsyncStream<Event>.Continuation
    private var task: Task<Void, Never>?

    public init(
        initialState: State,
        reduce: @escaping Reduce,
        handleEffect: @escaping HandleEffect,
        predicate: @escaping Predicate = { _, _ in false }
    ) {
        self.state = initialState
        self.reduce = reduce
        self.handleEffect = handleEffect
        self.predicate = predicate

        let (stream, continuation) = AsyncStream.makeStream(of: Event.self)
        self.continuation = continuation

        self.task = Task { [weak self] in
            for await event in stream {
                guard let self else { return }
                self.processEvent(event)
            }
        }
    }

    deinit {
        task?.cancel()
        continuation.finish()
    }

    private func processEvent(_ event: Event) {

        let (newState, effect) = reduce(state, event)

        if !predicate(state, newState) {
            state = newState
        }

        if let effect {
            let eventStream = handleEffect(effect)
            let continuation = self.continuation
            Task { [continuation] in
                for await event in eventStream {
                    continuation.yield(event)
                }
            }
        }
    }
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
public extension ObservableModel {

    func event(_ event: Event) {

        continuation.yield(event)
    }
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
public extension ObservableModel {

    typealias Reduce = (State, Event) -> (State, Effect?)
    typealias HandleEffect = (Effect) -> AsyncStream<Event>
    typealias Predicate = (State, State) -> Bool
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
public extension ObservableModel where State: Equatable {

    convenience init(
        initialState: State,
        reduce: @escaping Reduce,
        handleEffect: @escaping HandleEffect
    ) {
        self.init(
            initialState: initialState,
            reduce: reduce,
            handleEffect: handleEffect,
            predicate: ==
        )
    }
}
