//
//  RxViewModel+ext.swift
//
//
//  Created by Igor Malyarov on 20.01.2024.
//

import CombineSchedulers
import Foundation

public extension RxViewModel where State: Equatable {
    
    convenience init(
        initialState: State,
        reduce: @escaping Reduce,
        handleEffect: @escaping HandleEffect,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.init(
            initialState: initialState,
            reduce: reduce,
            handleEffect: handleEffect,
            predicate: ==,
            scheduler: scheduler
        )
    }
}

public extension RxViewModel {
    
    convenience init(
        initialState: State,
        reducer: any Reducer<State, Event, Effect>,
        effectHandler: any EffectHandler<Event, Effect>,
        predicate: @escaping Predicate = { _,_ in false },
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.init(
            initialState: initialState,
            reduce: reducer.reduce(_:_:),
            handleEffect: effectHandler.handleEffect(_:_:),
            predicate: predicate,
            scheduler: scheduler
        )
    }
}
