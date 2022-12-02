import Foundation
import FlipperPluginUtils

public struct FlipperErrorMessage {
    let message: String
    let name: String?
    let stacktrace: String?
    
    init(message: String,
         name: String? = nil,
         stacktrace: String? = nil) {
        self.message = message
        self.name = name
        self.stacktrace = stacktrace
    }
}

struct DeviceInfo: Codable {
    let deviceId: String
}

struct FlipperIDERequest: Codable {
    enum MethodType: String, Codable {
        case getPlugins
        case getBackgroundPlugins
    }
    let id: Int
    let method: MethodType
}

struct FlipperIDEPluginRequest {
    enum MethodType: String, Codable {
        case `init`
        case execute
        case `deinit`
        case isMethodSupported
    }
    let params: [String: Any]
    let method: MethodType
    let id: Int?
    
    static func fromData(_ data: Data) -> FlipperIDEPluginRequest? {
        guard let json = try? JSONSerialization.jsonObject(with: data,
                                                           options: []) as? [String: Any] else {
            return nil
        }
        let method = json["method"] as? String
        let methodType = MethodType(rawValue: method ?? "")
        let params = json["params"] as? [String: Any] ?? [:]
        let id = (json["id"] as? Int)
        if let methodType = methodType {
            return .init(params: params,
                         method: methodType,
                         id: id)
        } else {
            return nil
        }
    }
}
