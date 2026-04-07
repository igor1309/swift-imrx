//
//  AsyncEffectHandlerSpy.swift
//

final class AsyncEffectHandlerSpy<Event, Effect>
where Event: Equatable,
      Effect: Equatable {

    private(set) var effects = [Effect]()
    private var continuations = [AsyncStream<Event>.Continuation]()

    var callCount: Int { effects.count }

    func handleEffect(_ effect: Effect) -> AsyncStream<Event> {

        effects.append(effect)
        let (stream, continuation) = AsyncStream.makeStream(of: Event.self)
        continuations.append(continuation)
        return stream
    }

    func complete(with event: Event, at index: Int = 0) {

        continuations[index].yield(event)
        continuations[index].finish()
    }

    func yield(_ event: Event, at index: Int = 0) {

        continuations[index].yield(event)
    }

    func finish(at index: Int = 0) {

        continuations[index].finish()
    }
}
