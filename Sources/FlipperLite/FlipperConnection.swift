import Foundation

public typealias FlipperReceiver = (_ params: [String: Any],
                                    _ responder: FlipperResponder) -> Void

final public class FlipperConnection {
    private let pluginId: String
    private let client: FlipperMessageBus
    
    private var subscriptions = [String: FlipperReceiver]()
    
    public init(pluginId: String,
                client: FlipperMessageBus) {
        self.pluginId = pluginId
        self.client = client
    }
    
    /// Send an `execute` message to Flipper.
    /// Here is what client sends over the wire:
    /// { method: 'execute', params: { api: pluginID, method, params } }
    /// - Parameters:
    ///   - method: Method name that needs to be executed by Flipper
    ///   - params: Any extra params required for the method execution
    public func send(method: String,
                     params: [String : Any]) {
        let pluginParams: [String: Any] = [
            "api": pluginId,
            "method": method,
            "params": params
        ]
        let completeParams: [String : Any] = [
            "method": "execute",
            "params": pluginParams
        ]
        client.sendMessage(message: completeParams)
    }
    
    /**
     * Listen to messages for the method provided and execute a callback when one arrives.
     * Send response back to Flipper.
     * Read more about responses at https://fbflipper.com/docs/extending/new-clients#responding-to-messages
     */
    public func receive(method: String,
                        receiver: @escaping FlipperReceiver) {
        subscriptions[method] = receiver
    }
    
    public func hasReceiver(method: String) -> Bool {
        subscriptions[method] != nil
    }
    
    public func call(method: String,
                     params: [String: Any],
                     responder: FlipperResponder) {
        guard let receiver = subscriptions[method] else {
            let errorMessage = "Receiver \(method) not found."
            responder.error(response: .init(message: errorMessage))
            return
        }
        receiver(params, responder)
    }
}
