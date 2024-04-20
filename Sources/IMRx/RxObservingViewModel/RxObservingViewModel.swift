//
//  RxObservingViewModel.swift
//
//
//  Created by Igor Malyarov on 20.04.2024.
//

import Combine
import CombineSchedulers
import Foundation

public final class RxObservingViewModel<State, Event, Effect>: ObservableObject {
    
    @Published public private(set) var state: State
    
    private let observable: ObservableViewModel
    
    public init(
        initialState: State,
        observable: ObservableViewModel,
        observe: @escaping (State) -> Void,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.state = initialState
        self.observable = observable
        
        observable.$state
            .dropFirst()
            .handleEvents(receiveOutput: observe)
            .receive(on: scheduler)
            .assign(to: &$state)
    }
}

public extension RxObservingViewModel {
    
    func event(_ event: Event) {
        
        observable.event(event)
    }
}

public extension RxObservingViewModel {
    
    typealias ObservableViewModel = RxViewModel<State, Event, Effect>
}
