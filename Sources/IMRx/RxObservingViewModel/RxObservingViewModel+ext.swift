//
//  RxObservingViewModel+ext.swift
//
//
//  Created by Igor Malyarov on 20.04.2024.
//

import CombineSchedulers
import Foundation

public extension RxObservingViewModel {
    
    typealias Reduce = ObservableViewModel.Reduce
    typealias HandleEffect = ObservableViewModel.HandleEffect
    
    convenience init(
        initialState: State,
        reduce: @escaping Reduce,
        handleEffect: @escaping HandleEffect,
        predicate: @escaping (State, State) -> Bool = { _,_ in false },
        observe: @escaping (State) -> Void,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.init(
            initialState: initialState,
            observable: .init(
                initialState: initialState,
                reduce: reduce,
                handleEffect: handleEffect,
                predicate: predicate,
                scheduler: scheduler
            ),
            observe: observe,
            scheduler: scheduler
        )
    }
}

public extension RxObservingViewModel where State: Equatable {
    
    convenience init(
        initialState: State,
        reduce: @escaping Reduce,
        handleEffect: @escaping HandleEffect,
        observe: @escaping (State) -> Void,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.init(
            initialState: initialState,
            observable: .init(
                initialState: initialState,
                reduce: reduce,
                handleEffect: handleEffect,
                scheduler: scheduler
            ),
            observe: observe,
            scheduler: scheduler
        )
    }
}
