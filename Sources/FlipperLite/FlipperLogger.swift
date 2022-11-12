import Foundation

struct FlipperLogger {
    static func logInfo(_ info: String) {
        print("Flipper: \(info)")
    }
    
    static func logError(_ error: String) {
        print("FlipperError: \(error)")
    }
}
