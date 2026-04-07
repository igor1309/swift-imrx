//
//  ReducerSpy.swift
//

final class ReducerSpy<State, Event, Effect>
where State: Equatable,
      Event: Equatable,
      Effect: Equatable {

    private var stub: [(State, Effect?)]
    private(set) var messages = [Message]()

    var callCount: Int { messages.count }

    init(stub: [(State, Effect?)]) {

        self.stub = stub
    }

    func reduce(
        _ state: State,
        _ event: Event
    ) -> (State, Effect?) {

        messages.append((state, event))
        return stub.removeFirst()
    }

    typealias Message = (state: State, event: Event)
}
