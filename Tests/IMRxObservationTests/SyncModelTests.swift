//
//  SyncModelTests.swift
//

import ConcurrencyExtras
import IMRxObservation
import Observation
import XCTest

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
final class SyncModelTests: XCTestCase {

    func test_init_shouldNotCallReducer() {

        let (_, reducer) = makeSUT()

        XCTAssertEqual(reducer.messages.count, 0)
    }

    func test_event_shouldDeliverReducedStateBeforeReturning() {

        let (sut, _) = makeSUT(stub: [3])

        sut.event(1)

        XCTAssertEqual(sut.state, 3)
    }

    func test_event_shouldReduceEventsInOrder() {

        let (sut, reducer) = makeSUT(initialState: 0, stub: [1, 2])

        sut.event(10)
        sut.event(20)

        XCTAssertEqual(reducer.messages.map(\.state), [0, 1])
        XCTAssertEqual(reducer.messages.map(\.event), [10, 20])
        XCTAssertEqual(sut.state, 2)
    }

    func test_event_shouldNotNotifyObserverOnEqualState() {

        let (sut, _) = makeSUT(initialState: 5, stub: [5])
        let notified = LockIsolated(false)
        withObservationTracking { _ = sut.state } onChange: { notified.setValue(true) }

        sut.event(1)

        XCTAssertFalse(notified.value)
    }

    func test_event_shouldNotifyObserverOnChangedState() {

        let (sut, _) = makeSUT(initialState: 5, stub: [6])
        let notified = LockIsolated(false)
        withObservationTracking { _ = sut.state } onChange: { notified.setValue(true) }

        sut.event(1)

        XCTAssertTrue(notified.value)
    }

    func test_customPredicate_shouldDecideAssignment() {

        let sut = SyncModel<Int, Int>(initialState: 0, reduce: { $0 + $1 }, predicate: { _, new in new.isMultiple(of: 2) })

        sut.event(1)
        sut.event(1)

        XCTAssertEqual(sut.state, 1)
    }

    @MainActor
    func test_eventFromAnotherActor_shouldBeReducedAfterAwaitedHop() async {

        let sut = SyncModel<Int, Int>(initialState: 0, reduce: { $0 + $1 })
        let sender = Sender()

        await sender.send(1, to: { event in await MainActor.run { sut.event(event) } })
        await sender.send(2, to: { event in await MainActor.run { sut.event(event) } })

        XCTAssertEqual(sut.state, 3)
    }

    // MARK: - Helpers

    private typealias SUT = SyncModel<Int, Int>

    private func makeSUT(
        initialState: Int = 0,
        stub: [Int] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: SUT, reducer: SyncReducerSpy) {

        let reducer = SyncReducerSpy(stub: stub)
        let sut = SUT(initialState: initialState, reduce: reducer.reduce)

        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(reducer, file: file, line: line)

        return (sut, reducer)
    }
}

private final class SyncReducerSpy {

    private var stub: [Int]
    private(set) var messages = [(state: Int, event: Int)]()

    init(stub: [Int]) {

        self.stub = stub
    }

    func reduce(_ state: Int, _ event: Int) -> Int {

        messages.append((state, event))
        return stub.removeFirst()
    }
}

private actor Sender {

    func send(_ event: Int, to deliver: @Sendable (Int) async -> Void) async {

        await deliver(event)
    }
}
