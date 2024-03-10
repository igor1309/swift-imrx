//
//  EffectHandlerSpy.swift
//
//
//  Created by Igor Malyarov on 20.01.2024.
//

import IMRx

final class EffectHandlerSpy<Event, Effect>: EffectHandler
where Event: Equatable,
      Effect: Equatable {
    
    private(set) var messages = [Message]()
    
    var callCount: Int { messages.count }
    
    func handleEffect(
        _ effect: Effect,
        _ dispatch: @escaping Dispatch
    ) {
        messages.append((effect, dispatch))
    }
    
    @MainActor
    func complete(
        with event: Event,
        at index: Int = 0
    ) {
        messages[index].dispatch(event)
    }
    
    typealias Dispatch = @MainActor (Event) -> Void
    typealias Message = (effect: Effect, dispatch: Dispatch)
}
