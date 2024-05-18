//
//  HandleEffectDecoratorTests.swift
//
//
//  Created by Igor Malyarov on 18.05.2024.
//

import XCTest
import IMTools

final class HandleEffectDecoratorTests: XCTestCase {
    
    func test_init_shouldNotCallDecoratee() {
        
        let (_, decorateeSpy, decorationSpy) = makeSUT()
        
        XCTAssertEqual(decorateeSpy.callCount, 0)
        XCTAssertEqual(decorationSpy.callCount, 0)
    }
    
    func test_handleEffect_shouldCallDecorateeWithEffect() {
        
        let effect = makeEffect()
        let (sut, decorateeSpy, _) = makeSUT()
        
        sut.handleEffect(effect) { _ in }
        
        XCTAssertNoDiff(decorateeSpy.payloads, [effect])
    }
    
    func test_handleEffect_shouldDeliverDecorateeEvent() {
        
        let event = makeEvent()
        let (sut, decorateeSpy, _) = makeSUT()
        let exp = expectation(description: "wait for dispatch")
        var receivedEvent: Event?
        
        sut.handleEffect(makeEffect()) {
            
            receivedEvent = $0
            exp.fulfill()
        }
        
        decorateeSpy.complete(with: event)
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertNoDiff(receivedEvent, event)
    }
    
    func test_handleEffect_shouldNotDeliverDecorateeEventOnInstanceDeallocation() {
        
        var sut: SUT?
        let decorateeSpy: DecorateeSpy
        (sut, decorateeSpy, _) = makeSUT()
        var receivedEvent: Event?
        
        sut?.handleEffect(makeEffect()) { receivedEvent = $0 }
        sut = nil
        decorateeSpy.complete(with: makeEvent())
        
        XCTAssertNil(receivedEvent)
    }
    
    func test_handleEffect_shouldDecorateDecorateeCompletion() {
        
        let (sut, decorateeSpy, decorationSpy) = makeSUT()
        
        sut.handleEffect(makeEffect()) { _ in decorationSpy.dispatchEvent() }
        decorateeSpy.complete(with: makeEvent())
        
        XCTAssertNoDiff(decorationSpy.messages, [.startEffect, .dispatchEvent, .finishEffect])
    }
    
    // MARK: - Helpers
    
    private typealias SUT = HandleEffectDecorator<Event, Effect>
    private typealias DecorateeSpy = Spy<Effect, Event>
    
    private func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> (
        sut: SUT,
        decorateeSpy: DecorateeSpy,
        decorationSpy: DecorationSpy
    ) {
        let decorateeSpy = DecorateeSpy()
        let decorationSpy = DecorationSpy()
        let sut = SUT(
            decoratee: decorateeSpy.process(_:completion:),
            decoration: .init(
                onEffectStart: decorationSpy.startEffect,
                onEffectFinish: decorationSpy.finishEffect
            )
        )
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(decorateeSpy, file: file, line: line)
        trackForMemoryLeaks(decorationSpy, file: file, line: line)
        
        return (sut, decorateeSpy, decorationSpy)
    }
    
    private struct Effect: Equatable {
        
        let value: String
    }
    
    private struct Event: Equatable {
        
        let value: String
    }
    
    private func makeEffect(
        value: String = UUID().uuidString
    ) -> Effect {
        
        .init(value: value)
    }
    
    private func makeEvent(
        value: String = UUID().uuidString
    ) -> Event {
        
        .init(value: value)
    }
    
    private final class DecorationSpy {
        
        private(set) var messages = [Message]()
        
        var callCount: Int { messages.count }
        
        func finishEffect() {
            
            messages.append(.finishEffect)
        }
        
        func dispatchEvent() {
            
            messages.append(.dispatchEvent)
        }
        
        func startEffect() {
            
            messages.append(.startEffect)
        }
        
        enum Message {
            
            case finishEffect
            case dispatchEvent
            case startEffect
        }
    }
}
