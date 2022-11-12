import Foundation
import FlipperLite

final class ExamplePlugin: FlipperPlugin {
    let id: String = "Example"
    let runInBackground: Bool = true
    
    private var triggerCount: Int = 0
    
    private weak var connection: FlipperConnection?
    
    static let shared = ExamplePlugin()
    
    private init() {}
    
    func didConnect(connection: FlipperConnection) {
        self.connection = connection
        connection.receive(method: "displayMessage") { params, responder in
            // We are not covering the message received here as the intent of bi-directional communication is already covered in the Tic Tac Toe Plugin
            responder.success(response: .dict(["greeting": "Hello"]))
        }
    }
    
    func didDisconnect() {
        self.connection = nil
    }
    
    func triggerNotification() {
        connection?.send(method: "triggerNotification",
                         params: ["id": triggerCount ])
        triggerCount += 1
    }
}
