import Foundation

enum FlipperConnectionState {
    case secure(DeviceInfo)
    case unsecure
    
    var isSecure: Bool {
        if case (.secure(_)) = self {
            return true
        }
        return false
    }
}
