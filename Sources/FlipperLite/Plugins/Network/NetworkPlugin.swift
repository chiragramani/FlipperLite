import Foundation
import PluginUtils

public typealias FlipperNetworkAdapter = SKIOSNetworkAdapter

final public class NetworkPlugin: FlipperPlugin {
    public let id: String = "Network"
    public let runInBackground: Bool = true
    private let queue = DispatchQueue(label: "com.flipper.lite.network",
                                      qos: .background)
    private weak var connection: FlipperConnection?
    private static let bufferSize = 500
    
    private typealias CachedEvent = (method: String, params: [String: Any])
    private var buffer = RingBuffer<CachedEvent>(count: NetworkPlugin.bufferSize)
    
    private let networkAdapter: SKNetworkAdapterDelegate
    
    public init(networkAdapter: SKNetworkAdapterDelegate) {
        self.networkAdapter = networkAdapter
        networkAdapter.delegate = self
    }
    
    public func didConnect(connection: FlipperConnection) {
        queue.async { [weak self] in
            self?.connection = connection
            self?.sendBufferedEvents()
        }
    }
    
    public func didDisconnect() {
        queue.async { [weak self] in
            self?.connection = nil
        }
    }
    
    private func sendBufferedEvents() {
        guard let connection = connection else { return }
        while let cachedEvent = buffer.read() {
            connection.send(method: cachedEvent.method,
                            params: cachedEvent.params)
        }
    }
    
    private func send(cachedEvent: CachedEvent) {
        queue.async { [weak self] in
            if let connection = self?.connection {
                connection.send(method: cachedEvent.method,
                                params: cachedEvent.params)
            } else {
                self?.buffer.write(cachedEvent)
            }
        }
    }
}

extension NetworkPlugin: SKNetworkReporterDelegate {
    public func didObserveRequest(_ request: SKRequestInfo!) {
        var headers = [[String: Any]]()
        request.request?.allHTTPHeaderFields?.keys.forEach { key in
            let header = [
                "key": key,
                "value": request.request?.allHTTPHeaderFields?[key] ?? NSNull() as Any
            ]
            headers.append(header)
        }
        send(
            cachedEvent: (
                method: "newRequest",
                params: [
                    "id": request.identifier,
                    "timestamp": request.timestamp,
                    "method": request.request?.httpMethod ?? NSNull(),
                    "url" : request.request?.url?.absoluteString ?? NSNull(),
                    "headers" : headers,
                    "data" : request.body ?? NSNull()
                ]
            )
        )
    }
    
    public func didObserveResponse(_ response: SKResponseInfo!) {
        // Only supports HTTP(S) calls
        guard let httpResponse = response.response.self as? HTTPURLResponse else {
            return
        }
        var headers = [[String: Any]]()
        httpResponse.allHeaderFields.keys.forEach { key in
            let header = [
                "key": key,
                "value": httpResponse.allHeaderFields[key] ?? NSNull()
            ]
            headers.append(header)
        }
        send(
            cachedEvent: (
                method: "newResponse",
                params: [
                    "id": response.identifier,
                    "timestamp": response.timestamp,
                    "status": httpResponse.statusCode,
                    "reason": HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
                    "headers" : headers,
                    "data" : response.body ?? NSNull()
                ]
            )
        )
    }
}
