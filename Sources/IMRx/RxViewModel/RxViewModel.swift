//
//  RxViewModel.swift
//
//
//  Created by Igor Malyarov on 14.01.2024.
//

import Combine
import CombineSchedulers
import Foundation

public final class RxViewModel<State, Event, Effect>: ObservableObject {
    
    @Published public private(set) var state: State
    
    private let reduce: Reduce
    private let handleEffect: HandleEffect
    
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let eventQueue = PassthroughSubject<Event, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        initialState: State,
        reduce: @escaping Reduce,
        handleEffect: @escaping HandleEffect,
        predicate: @escaping (State, State) -> Bool = { _, _ in false },
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.state = initialState
        self.reduce = reduce
        self.handleEffect = handleEffect
        self.scheduler = scheduler
        
        eventQueue
            .receive(on: scheduler)
            .flatMap { [weak self] event -> AnyPublisher<Event, Never> in
                
                guard let self = self else {
                    
                    return Empty().eraseToAnyPublisher()
                }
                
                let (newState, effect) = self.reduce(self.state, event)
                self.state = newState
                
                if let effect {
                    
                    return Future<Event, Never> { promise in
                        
                        self.handleEffect(effect) { event in
                            
                            promise(.success(event))
                        }
                    }
                    .eraseToAnyPublisher()
                    
                } else {
                    
                    return Empty().eraseToAnyPublisher()
                }
            }
            .sink { [weak self] event in
                
                self?.event(event)
            }
            .store(in: &cancellables)
    }
}

public extension RxViewModel {
    
    func event(_ event: Event) {
        
        eventQueue.send(event)
    }
}

public extension RxViewModel {
    
    typealias Reduce = (State, Event) -> (State, Effect?)
    typealias HandleEffect = (Effect, @escaping (Event) -> Void) -> Void
}
