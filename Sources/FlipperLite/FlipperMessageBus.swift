import Foundation

public protocol FlipperMessageBus {
    func sendMessage(message: [String: Any])
}
