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
        reducer: any Reducer<State, Event, Effect>,
        effectHandler: some EffectHandler<Event, Effect>,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        
        self.init(
            initialState: initialState,
            reduce: reducer.reduce(_:_:),
            handleEffect: effectHandler.handleEffect(_:_:),
            scheduler: scheduler
        )
    }
}
