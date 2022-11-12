import Combine

final class GameController {
    private let currentState = CurrentValueSubject<GameState, Error>(GameState.defaultState)
    var sendClosure: ((_ index: Int) -> Void)?
    
    var gameState: AnyPublisher<GameState, Error> {
        currentState.eraseToAnyPublisher()
    }
    
    func updateState(from params: [String: Any]) {
        currentState.value = GameState.state(from: params)
    }
}
