import Foundation

public enum FlipperPluginReceiverRes {
    case pluginNames([String])
    case isSupported(Bool)
    case dict([String: Any])
}

public struct FlipperResponder {
    let responderId: Int?
    let client: FlipperMessageBus
    
    public init(responderId: Int?,
         client: FlipperMessageBus) {
        self.responderId = responderId
        self.client = client
    }
    
    public func success(response: FlipperPluginReceiverRes) {
        var allParams = [String: Any]()
        allParams["id"] = responderId
        switch response {
        case .isSupported(let booleanValue):
            allParams["success"] = ["isSupported": booleanValue]
        case .pluginNames(let pluginNames):
            allParams["success"] = ["plugins": pluginNames]
        case .dict(let dict):
            allParams["success"] = dict
        }
        client.sendMessage(message: allParams)
    }
    
    public func error(response: FlipperErrorMessage) {
        let errorParams: [String: Any] =  [
            "message": response.message,
            "name": response.name ?? NSNull(),
            "stacktrace": response.stacktrace ?? Thread.callStackSymbols,
        ]
        let allParams: [String: Any] = [
            "id": responderId ?? NSNull(),
            "error": errorParams
        ]
        client.sendMessage(message: allParams)
    }
}
