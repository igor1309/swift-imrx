//
//  ObservableModelIsolationTests.swift
//

import Dispatch
import Foundation
import IMRxObservation
import XCTest

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
final class ObservableModelIsolationTests: XCTestCase {

    @MainActor
    func test_modelMadeOnMainActor_shouldReduceOnMainThread() async {

        var reducedOnMain = [Bool]()
        let sut = ObservableModel<Int, Int, Never>(
            initialState: 0,
            reduce: { state, event in
                reducedOnMain.append(Thread.isMainThread)
                return (state + event, nil)
            },
            handleEffect: { _ in AsyncStream { $0.finish() } },
            predicate: ==
        )

        sut.event(1)
        sut.event(2)
        await settle { sut.state == 3 }

        XCTAssertEqual(sut.state, 3)
        XCTAssertEqual(reducedOnMain, [true, true])
    }

    func test_modelMadeInActor_shouldReduceOnThatActor() async {

        let owner = Owner()

        let (state, reducedOnOwner) = await owner.run(events: [1, 2])

        XCTAssertEqual(state, 3)
        XCTAssertEqual(reducedOnOwner, [true, true])
    }

    func test_modelMadeInActor_shouldDeliverEffectResultsOnThatActor() async {

        let owner = Owner()

        let (state, reducedOnOwner) = await owner.runEffect()

        XCTAssertEqual(state, 10)
        XCTAssertEqual(reducedOnOwner, [true, true])
    }
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
private actor Owner {

    private static let key = DispatchSpecificKey<Bool>()
    private let queue: DispatchSerialQueue

    init() {

        let queue = DispatchSerialQueue(label: "Owner")
        queue.setSpecific(key: Self.key, value: true)
        self.queue = queue
    }

    nonisolated var unownedExecutor: UnownedSerialExecutor {

        queue.asUnownedSerialExecutor()
    }

    func run(events: [Int]) async -> (Int, [Bool]) {

        var reducedOnOwner = [Bool]()
        let sut = ObservableModel<Int, Int, Never>(
            initialState: 0,
            reduce: { state, event in
                reducedOnOwner.append(DispatchQueue.getSpecific(key: Self.key) == true)
                return (state + event, nil)
            },
            handleEffect: { _ in AsyncStream { $0.finish() } },
            predicate: ==
        )

        for event in events { sut.event(event) }
        await settle { sut.state == events.reduce(0, +) }

        return (sut.state, reducedOnOwner)
    }

    func runEffect() async -> (Int, [Bool]) {

        var reducedOnOwner = [Bool]()
        let sut = ObservableModel<Int, Int, Int>(
            initialState: 0,
            reduce: { state, event in
                reducedOnOwner.append(DispatchQueue.getSpecific(key: Self.key) == true)
                return event == 0 ? (state, 10) : (event, nil)
            },
            handleEffect: { effect in
                AsyncStream { $0.yield(effect); $0.finish() }
            },
            predicate: ==
        )

        sut.event(0)
        await settle { sut.state == 10 }

        return (sut.state, reducedOnOwner)
    }
}

private func settle(
    isolation: isolated (any Actor)? = #isolation,
    until done: () -> Bool
) async {

    for _ in 0..<1_000 where !done() { await Task.yield() }
}
