import Foundation

/// Retreives configuration values stored in environment variables.
struct FlipperEnvironmentVariables {
    static func getInsecurePort() -> Int {
        extractIntFromPropValue(getFlipperPortsVariable(),
                                atIndex: 0,
                                withDefault: DEFAULT_INSECURE_PORT)
    }
    
    static func getSecurePort() -> Int {
        extractIntFromPropValue(getFlipperPortsVariable(),
                                atIndex: 1,
                                withDefault: DEFAULT_SECURE_PORT)
    }
    
    // MARK: Private
    
    private static let DEFAULT_INSECURE_PORT = 9089
    private static let DEFAULT_SECURE_PORT = 9088
    
    private static func getFlipperPortsVariable() -> String? {
        let value = ProcessInfo().environment["FLIPPER_PORTS"]
        if value?.isEmpty == true {
            return UserDefaults.standard.string(forKey: "com.flipper.lite.ports")
        }
        return value
    }
    
    private static func extractIntFromPropValue(_ value: String?,
                                                atIndex index: Int,
                                                withDefault defaultValue: Int) -> Int {
        guard let value = value else {
            return defaultValue
        }
        let components = value.components(separatedBy: ",")
        if index < components.count {
            return Int(components[index]) ?? defaultValue
        }
        return defaultValue
    }
}
