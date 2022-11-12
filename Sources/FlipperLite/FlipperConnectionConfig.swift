import Foundation

#if canImport(UIKit)
import UIKit
private let currentDevice = UIDevice.current.model
#endif
#if canImport(AppKit)
import AppKit
private let currentDevice = Host.current().name ?? "Host"
#endif

public struct FlipperConnectionConfig {
    public let urlSession: URLSession
    
    public init(urlSession: URLSession = .init(configuration: .default)) {
        self.urlSession = urlSession
    }
}

extension FlipperConnectionConfig {
    func queryItems(deviceID: String? = nil,
                    csrPath: String? = nil) -> [URLQueryItem] {
        var items = [URLQueryItem]()
        items.append(.init(name: "os", value: FlipperConnectionConfig.osName))
        items.append(.init(name: "app", value: FlipperConnectionConfig.appName))
        items.append(.init(name: "device", value: FlipperConnectionConfig.deviceModel))
        items.append(.init(name: "device_id", value: deviceID ?? "unknown"))
        items.append(.init(name: "sdk_version", value: String(Self.sdkVersion)))
        if let csrPath {
            items.append(.init(name: "csr_path", value: csrPath))
        }
        return items
    }
    
    private static let appName: String =  {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ??
        Bundle.main.bundleURL.lastPathComponent.components(separatedBy: ".").first!
    }()
    
    // Not a public-facing version number.
    // Used for compatibility checking with desktop flipper.
    // To be bumped for every core platform interface change.
    private static let sdkVersion: Int = 4
    
    private static let deviceModel: String = {
        #if targetEnvironment(simulator)
            return "\(currentDevice) Simulator"
        #else
            return currentDevice
        #endif
    }()
    
    private static let osName: String = {
        #if os(iOS)
            return "iOS"
        #elseif os(watchOS)
            return "watchOS"
        #elseif os(tvOS)
            return "tvOS"
        #elseif os(macOS)
            return "macOS"
        #else
            return "Browser"
        #endif
    }()
}
