//
//  ObservableModelTests.swift
//
//
//  Created by Igor Malyarov on 07.04.2026.
//

import ConcurrencyExtras
import IMRxObservation
import XCTest

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
final class ObservableModelTests: XCTestCase {

    func test_init_shouldNotCallCollaborators() async {

        await withMainSerialExecutor {
            let (_, reducer, effectHandler) = makeSUT()

            XCTAssertNoDiff(reducer.callCount, 0)
            XCTAssertNoDiff(effectHandler.callCount, 0)
        }
    }

    func test_event_shouldCallReducerWithGivenStateAndEvent() async {

        await withMainSerialExecutor {
            let initialState = makeState()
            let event: Event = .resetValue
            let (sut, reducer, _) = makeSUT(
                initialState: initialState,
                stub: makeStub()
            )

            sut.event(event)
            await settle()

            XCTAssertNoDiff(reducer.messages.map(\.state), [initialState])
            XCTAssertNoDiff(reducer.messages.map(\.event), [event])
        }
    }

    func test_event_shouldNotCallEffectHandlerOnNilEffect() async {

        await withMainSerialExecutor {
            let effect: Effect? = nil
            let (sut, _, effectHandler) = makeSUT(
                stub: makeStub(effect)
            )

            sut.event(.resetValue)
            await settle()

            XCTAssertNoDiff(effectHandler.callCount, 0)
        }
    }

    func test_event_shouldCallEffectHandlerOnNonNilEffect() async {

        await withMainSerialExecutor {
            let effect: Effect = .load
            let (sut, _, effectHandler) = makeSUT(
                stub: makeStub(effect)
            )

            sut.event(.resetValue)
            await settle()

            XCTAssertNoDiff(effectHandler.effects, [effect])
        }
    }

    func test_event_shouldCallReducerTwiceOnEffect() async {

        await withMainSerialExecutor {
            let (sut, reducer, effectHandler) = makeSUT(
                initialState: makeState(),
                stub: makeStub(.load), makeStub()
            )

            sut.event(.resetValue)
            await settle()

            let value = UUID().uuidString
            effectHandler.complete(with: .changeValueTo(value))
            await settle()

            XCTAssertNoDiff(reducer.callCount, 2)
        }
    }

    func test_event_shouldReduceWithGivenStateAndEvent() async {

        await withMainSerialExecutor {
            let initialState = makeState()
            let first = makeStub(.load)
            let last = makeStub()
            let (sut, reducer, effectHandler) = makeSUT(
                initialState: initialState,
                stub: first, last
            )

            sut.event(.resetValue)
            await settle()

            let value = UUID().uuidString
            effectHandler.complete(with: .changeValueTo(value))
            await settle()

            XCTAssertNoDiff(reducer.messages.map(\.state), [
                initialState,
                first.0,
            ])
            XCTAssertNoDiff(reducer.messages.map(\.event), [
                .resetValue,
                .changeValueTo(value),
            ])
        }
    }

    func test_event_shouldDeliverStateValues() async {

        await withMainSerialExecutor {
            let initialState = makeState()
            let first = makeStub(.load)
            let last = makeStub()
            let (sut, _, effectHandler) = makeSUT(
                initialState: initialState,
                stub: first, last
            )

            XCTAssertNoDiff(sut.state, initialState)

            sut.event(.resetValue)
            await settle()

            XCTAssertNoDiff(sut.state, first.0)

            let value = UUID().uuidString
            effectHandler.complete(with: .changeValueTo(value))
            await settle()

            XCTAssertNoDiff(sut.state, last.0)
        }
    }

    func test_event_shouldUpdateStateOnSuccessiveEvents() async {

        await withMainSerialExecutor {
            let (sut, _, _) = makeSUT(
                initialState: .init(value: ""),
                stub: (State(value: "a"), nil),
                      (State(value: "ab"), nil)
            )

            sut.event(.resetValue)
            sut.event(.resetValue)
            await settle()

            XCTAssertNoDiff(sut.state, State(value: "ab"))
        }
    }

    func test_event_shouldUsePredicateToSkipStateUpdate() async {

        await withMainSerialExecutor {
            let newState = makeState()
            let (sut, _, _) = makeSUT(
                stub: (newState, nil),
                predicate: { _, _ in true }
            )
            let initialState = sut.state

            sut.event(.resetValue)
            await settle()

            XCTAssertNoDiff(sut.state, initialState, "Expected state unchanged due to predicate.")
        }
    }

    func test_event_shouldUsePredicateToAllowStateUpdate() async {

        await withMainSerialExecutor {
            let newState = makeState()
            let (sut, _, _) = makeSUT(
                stub: (newState, nil),
                predicate: { _, _ in false }
            )

            sut.event(.resetValue)
            await settle()

            XCTAssertNoDiff(sut.state, newState)
        }
    }

    func test_shouldNotDeliverEffectEventsOnInstanceDeallocation() async {

        await withMainSerialExecutor {
            var sut: SUT?
            let effectHandler: EffectHandleSpy
            let reducer: ReduceSpy
            (sut, reducer, effectHandler) = makeSUT(
                stub: makeStub(.load), makeStub()
            )

            sut?.event(.resetValue)
            await settle()

            let stateBeforeDealloc = sut?.state
            sut = nil
            effectHandler.complete(with: .changeValueTo(anyMessage()))
            await settle()

            XCTAssertNoDiff(reducer.callCount, 1, "No further events should be processed after deallocation")
            _ = stateBeforeDealloc
        }
    }

    func test_effectHandler_shouldEmitMultipleEvents() async {

        await withMainSerialExecutor {
            let first = makeState()
            let second = makeState()
            let third = makeState()
            let (sut, reducer, effectHandler) = makeSUT(
                stub: (first, .load),
                      (second, nil),
                      (third, nil)
            )

            sut.event(.resetValue)
            await settle()

            effectHandler.yield(.resetValue)
            await settle()

            effectHandler.complete(with: .resetValue)
            await settle()

            XCTAssertNoDiff(reducer.callCount, 3)
            XCTAssertNoDiff(sut.state, third)
        }
    }

    // MARK: - Helpers

    private typealias SUT = ObservableModel<State, Event, Effect>
    private typealias ReduceSpy = ReducerSpy<State, Event, Effect>
    private typealias EffectHandleSpy = AsyncEffectHandlerSpy<Event, Effect>

    private func makeSUT(
        initialState: State = makeState(),
        stub: (State, Effect?)...,
        predicate: @escaping (State, State) -> Bool = { _, _ in false },
        file: StaticString = #file,
        line: UInt = #line
    ) -> (
        sut: SUT,
        reducer: ReduceSpy,
        effectHandler: EffectHandleSpy
    ) {
        let reducer = ReduceSpy(stub: stub)
        let effectHandler = EffectHandleSpy()
        let sut = SUT(
            initialState: initialState,
            reduce: reducer.reduce,
            handleEffect: effectHandler.handleEffect,
            predicate: predicate
        )

        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(reducer, file: file, line: line)
        trackForMemoryLeaks(effectHandler, file: file, line: line)

        return (sut, reducer, effectHandler)
    }

    fileprivate struct State: Equatable {

        let value: String
    }

    private enum Event: Equatable {

        case changeValueTo(String)
        case resetValue
    }

    private enum Effect: Equatable {

        case load
    }

    private func makeStub(
        _ effect: Effect? = nil
    ) -> (State, Effect?) {

        (makeState(), effect)
    }

    private func settle() async {

        await Task.megaYield()
    }
}

private func makeState(
    value: String = UUID().uuidString
) -> ObservableModelTests.State {

    .init(value: value)
}
