import Foundation
import FlipperLite

final class TicTacToePlugin: FlipperPlugin {
    let id: String = "ReactNativeTicTacToe"
    let gameController: GameController
    
    init(gameController: GameController) {
        self.gameController = gameController
    }
    
    func didConnect(connection: FlipperConnection) {
        // Store a reference to connection to send client game events to Flipper IDE.
        self.connection = connection
        // Request the Initial State
        connection.send(method: "GetState", params: [:])
        // Subscribe to the events from the Flipper Desktop
        connection.receive(method: "SetState") { params, _ in
            self.gameController.updateState(from: params)
        }
    }
    
    func didDisconnect() {
        connection = nil
    }
    
    var runInBackground: Bool {
        return false
    }
    
    // MARK: Private
    
    private weak var connection: FlipperConnection? {
        didSet {
            gameController.sendClosure = { [weak self] (index:Int) -> Void in
                self?.connection?.send(method: "XMove",
                                       params: ["move": index]
                )
            }
        }
    }
}
