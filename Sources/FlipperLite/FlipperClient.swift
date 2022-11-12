import Foundation

final public class FlipperClient {
    public static let shared = FlipperClient(plugins: [])
    
    fileprivate(set) var pluginsMap: [String: FlipperPlugin] = [:]
    fileprivate(set) var connections: [String: FlipperConnection] = [:]
    
    private let connectionConfig = FlipperConnectionConfig()
    private var webSocketTask: URLSessionWebSocketTask?
    private let flipperQueue = DispatchQueue(label: "com.flipper.swift")
    fileprivate var sonarDirectoryURL: URL!
    private var connectionConstants: ConnectionConstants!
    private var connectionState: FlipperConnectionState = .unsecure
    private let portForwarder = FlipperPortForwarder()
    
    // Retries
    private static let reconnectInterval: TimeInterval = 5
    private static let maxRetryAttempts = 5
    private var currentRetryAttempts = 0
    
    private init(plugins: [FlipperPlugin]) {
        setupInitialState()
        if let sonarDirectoryURL {
            self.connectionConstants = ConnectionConstants(sonarDirectoryURL: sonarDirectoryURL)
            plugins.forEach { pluginsMap[$0.id] = $0 }
        }
    }
    
    deinit {
        disconnect(with: .goingAway)
    }
}

// MARK: Public

public extension FlipperClient {
    var isConnected: Bool {
        webSocketTask?.state == .running
    }
    
    var isConnectedSecurely: Bool {
        webSocketTask?.state == .running && connectionState.isSecure
    }
    
    func addPlugin(_ plugin: FlipperPlugin) throws {
        try flipperQueue.sync {
            pluginsMap[plugin.id] = plugin
            if isConnectedSecurely {
                try refreshPlugins()
            }
        }
    }
    
    func disconnectFromFlipper() {
        flipperQueue.sync { [weak self] in
            self?.disconnect(with: .normalClosure)
        }
    }
    
    func connectToFlipper() {
        guard sonarDirectoryURL != nil, !isConnected else { return }
        flipperQueue.async { [weak self] in
            self?.initiateConnect()
        }
    }
}

// MARK: Private

// MARK: FlipperMessageBus

extension FlipperClient: FlipperMessageBus {
    public func sendMessage(message: [String: Any]) {
        guard isConnected,
              let webSocketTask = webSocketTask else { return }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: transformedDict(message),
                                                      options: [.fragmentsAllowed])
            let stringifiedJSON = String(data: jsonData,
                                         encoding: .utf8) ?? ""
            let message = URLSessionWebSocketTask.Message.string(stringifiedJSON)
            webSocketTask.send(message) { error in
                if let error = error {
                    FlipperLogger.logError("WebSocket couldn’t send message: \(message) because of: \(error.localizedDescription)")
                }
            }
        } catch let error {
            FlipperLogger.logError("Couldn't serialize message to JSON representation: \(message) because of: \(error.localizedDescription)")
        }
    }
    
    private func transformedValue(_ value: Any) -> Any {
        // This might not be exhaustive.
        if let dataValue = value as? Data {
            let stringValue = String(data: dataValue,
                                     encoding: .utf8)
            return stringValue
        }
        if let dictValue = value as? [String: Any] {
            return dictValue.mapValues { transformedValue($0) }
        }
        if let arrayValue = value as? Array<Any> {
            return arrayValue.map { transformedValue($0) }
        }
        return value
    }
    
    private func transformedDict(_ dict: [String: Any]) -> [String: Any] {
        var newDict = [String: Any]()
        dict.forEach { (key, value) in
            if let dictValue = value as? [String: Any] {
                newDict[key] = transformedDict(dictValue)
            } else {
                newDict[key] = transformedValue(value)
            }
        }
        return newDict
    }
}

// MARK: WebSocket connectivity

private extension FlipperClient {
    func connectPlugin(_ plugin: FlipperPlugin) {
        let connection = FlipperConnection(pluginId: plugin.id,
                                           client: self)
        connections[plugin.id] = connection
        plugin.didConnect(connection: connection)
    }
    
    func disconnectPlugin(_ plugin: FlipperPlugin) {
        guard let _ = connections[plugin.id] else {
            return
        }
        plugin.didDisconnect()
        connections.removeValue(forKey: plugin.id)
    }
    
    func initiateConnect() {
        guard !isConnected else { return }
        portForwarder.setup()
        if hasRequiredCertFiles,
           let deviceInfo = persistedDeviceInfo {
            self.connectionState = .secure(deviceInfo)
            connectOnSecurePorts(deviceInfo: deviceInfo)
        } else {
            self.connectionState = .unsecure
            // Do Cert Exchange
            connectOnUnsecurePorts()
        }
    }
    
    func disconnect(with closeCode: URLSessionWebSocketTask.CloseCode) {
        // Unsubscribing
        webSocketTask?.receive { _ in }
        webSocketTask?.cancel(with: closeCode,
                              reason: nil)
        pluginsMap.values.forEach {
            $0.didDisconnect()
        }
        webSocketTask = nil
        portForwarder.reset()
    }
}

// MARK: Refresh Plugins

extension FlipperClient {
    func refreshPlugins() throws {
        sendMessage(
            message: [
                "method": "refreshPlugins"
            ]
        )
    }
}

// MARK: WebSocket subscriptions

private extension FlipperClient {
    
    private func parse(_ string: String,
                       webSocketTask: URLSessionWebSocketTask) {
        guard let data = string.data(using: .utf8) else {
            FlipperLogger.logError("Add support for unhandled message:\(string)")
            return
        }
        if let deviceInfo = try? JSONDecoder().decode(DeviceInfo.self,
                                                      from: data) {
            // Cert exchange was successful.
            // Let's connect on the secure port now.
            webSocketTask.receive { _ in }
            persistDeviceInfo(deviceInfo: deviceInfo)
            connectOnSecurePorts(deviceInfo: deviceInfo)
        } else if let request = try? JSONDecoder().decode(FlipperIDERequest.self,
                                                          from: data) {
            handleIDERequest(request,
                             webSocketTask: webSocketTask)
        } else if let request = FlipperIDEPluginRequest.fromData(data) {
            handlePluginRequest(request,
                                webSocketTask: webSocketTask)
        } else {
            FlipperLogger.logError("Add support for unhandled message:\(string)")
        }
    }
    
    func subscribe(webSocketTask: URLSessionWebSocketTask?) {
        guard let webSocketTask = webSocketTask else { return }
        webSocketTask.receive { [weak self] result in
            switch result {
            case .failure(let error):
                if webSocketTask.state == .running {
                    FlipperLogger.logError("Error while processing frames: \(error.localizedDescription)")
                    /// This re-subscription is necessary to listen to new messages.
                    self?.subscribe(webSocketTask: webSocketTask)
                } else {
                    FlipperLogger.logError("Failed to connect to the Flipper IDE: \(error.localizedDescription)")
                    self?.reconnectIfNeeded(on: error)
                }
            case .success(let message):
                self?.onSubscriptionSuccess()
                switch message {
                case .data(_):
                    /// Given the testing so far, I didn't find data being received.
                    /// Add support for this use-case whenever we see this.
                    FlipperLogger.logError("Data parsing currently not present. Handle this use-case")
                case .string(let string):
                    self?.parse(string,
                                webSocketTask: webSocketTask)
                    /// This re-subscription is necessary to listen to new messages.
                    self?.subscribe(webSocketTask: webSocketTask)
                @unknown default:
                    FlipperLogger.logError("Handle this Unknown value: URLSessionWebSocketTask.Message': \(message) may have additional unknown values, possibly added in future versions")
                }
            }
        }
    }
    
    private func handleIDERequest(_ request: FlipperIDERequest,
                                  webSocketTask: URLSessionWebSocketTask) {
        let responder = FlipperResponder(responderId: request.id,
                                         client: self)
        switch request.method {
        case .getPlugins:
            let allPlugins = Array(pluginsMap.keys)
            responder.success(response: .pluginNames(allPlugins))
        case .getBackgroundPlugins:
            let backgroundPlugins = Array(pluginsMap.filter { $0.value.runInBackground }.keys)
            responder.success(response: .pluginNames(backgroundPlugins))
        }
    }
    
    private func handlePluginRequest(_ request: FlipperIDEPluginRequest,
                                     webSocketTask: URLSessionWebSocketTask) {
        let responder = FlipperResponder(responderId: request.id,
                                         client: self)
        switch request.method {
        case .`init`, .deinit:
            let pluginIdentifier = request.params["plugin"] as? String ?? ""
            if let plugin = pluginsMap[pluginIdentifier] {
                request.method == .`init` ?
                connectPlugin(plugin) :
                disconnectPlugin(plugin)
            } else {
                let errorMessage = "Plugin \(pluginIdentifier) not found for method \(request.method.rawValue)"
                responder.error(response: .init(message: errorMessage,
                                                name: "PluginNotFound",
                                                stacktrace: nil))
            }
        case .execute:
            let pluginIdentifier = request.params["api"] as? String ?? ""
            let method = request.params["method"] as? String ?? ""
            if let connection = connections[pluginIdentifier] {
                connection.call(method: method,
                                params: request.params["params"] as? [String: Any] ?? [:],
                                responder: responder)
            } else {
                let errorMessage = "Connection \(pluginIdentifier) not found for plugin identifier"
                responder.error(response: .init(message: errorMessage,
                                                name: "ConnectionNotFound",
                                                stacktrace: nil))
            }
        case .isMethodSupported:
            let pluginIdentifier = request.params["api"] as? String ?? ""
            let method = request.params["method"] as? String ?? ""
            if let connection = connections[pluginIdentifier] {
                responder.success(response: .isSupported(connection.hasReceiver(method: method)))
            } else {
                let errorMessage = "Connection \(pluginIdentifier) not found for plugin identifier"
                responder.error(response: .init(message: errorMessage,
                                                name: "ConnectionNotFound",
                                                stacktrace: nil))
            }
        }
    }
}

// MARK: Reconnect on Error

private extension FlipperClient {
    func reconnectIfNeeded(on error: Error?) {
        if let error = error as? FlipperError {
            handle(error)
        } else if (error as? NSError)?.code == -1005 {
            flipperQueue.asyncAfter(deadline: .now() + FlipperClient.reconnectInterval) { [weak self] in
                self?.initiateConnect()
            }
        } else {
            resetDiskState()
            guard currentRetryAttempts <= FlipperClient.maxRetryAttempts - 1 else {
                return
            }
            currentRetryAttempts += 1
            flipperQueue.asyncAfter(deadline: .now() + FlipperClient.reconnectInterval) { [weak self] in
                self?.initiateConnect()
            }
        }
    }
    
    func onSubscriptionSuccess() {
        // Reset retry attempts
        currentRetryAttempts = 0
    }
    
    private func handle(_ error: FlipperError) {
        switch error {
        case .ideNotOpen:
            flipperQueue.asyncAfter(deadline: .now() + FlipperClient.reconnectInterval) { [weak self] in
                self?.initiateConnect()
            }
        case let .invalidURL(urlString, queryItems):
            FlipperLogger.logError(
            """
            Failed to initialize Flipper SDK as URL could not be constructed.
            URLBase: \(urlString),
            queryItems: \(queryItems)
            """
            )
            return
        case .requireMinVersioniOS15:
            disconnect(with: .normalClosure)
            return
        }
    }
}

private extension FlipperClient {
    private func setupInitialState() {
        createSonarDirectory()
    }
    
    private func createSonarDirectory(_ fileManager: FileManager = .default) {
        guard let privateAppDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            FlipperLogger.logError("Failed to initialize Flipper as sonar directory couldn't be created.")
            return
        }
        let sonarDirectoryURL = privateAppDirectory.appendingPathComponent("sonar")
        if !fileManager.fileExists(atPath: sonarDirectoryURL.absoluteString) {
            do {
                try fileManager.createDirectory(at: sonarDirectoryURL,
                                                withIntermediateDirectories: true)
            } catch let error {
                FlipperLogger.logError("Failed to initialize Flipper as sonar directory couldn't be created: \(error.localizedDescription)")
                return
            }
        }
        self.sonarDirectoryURL = sonarDirectoryURL
    }
}

private extension FlipperClient {
    private func connectOnUnsecurePorts() {
        connectTask(connectionState: .unsecure)
    }
    
    private func connectOnSecurePorts(deviceInfo: DeviceInfo) {
        connectTask(connectionState: .secure(deviceInfo))
    }
    
    private func connectTask(connectionState: FlipperConnectionState) {
        let task = FlipperConnectTask(sonarDirectoryURL: sonarDirectoryURL,
                                      connectionConstants: connectionConstants,
                                      connectionConfig: connectionConfig,
                                      connectionState: connectionState)
        task.onInit = { [weak self] (webSocketTask) in
            self?.webSocketTask = webSocketTask
            self?.connectionState = connectionState
            self?.subscribe(webSocketTask: webSocketTask)
        }
        task.onError = { [weak self] error in
            self?.reconnectIfNeeded(on: error)
        }
        do {
            try task.connect()
        } catch let error {
            if (error as? FlipperError) == nil {
                FlipperLogger.logError("Flipper connection failed: \(error.localizedDescription)")
            }
        }
    }
}


private extension FlipperClient {
    var hasRequiredCertFiles: Bool {
        [
            connectionConstants.caCertFilePath,
            connectionConstants.clientCertFilePath,
            connectionConstants.privateKeyFilePath,
            connectionConstants.connectionConfigPath
        ].first {
            (try? String(contentsOfFile: $0)) ?? "" == ""
        } == nil
    }
    
    private func persistDeviceInfo(deviceInfo: DeviceInfo) {
        guard let encodedDeviceInfo = try? JSONEncoder().encode(deviceInfo) else {
            return
        }
        let stringValue = String(data: encodedDeviceInfo,
                                 encoding: .utf8)
        try? stringValue?.write(toFile: connectionConstants.connectionConfigPath,
                                atomically: true,
                                encoding: .utf8)
    }
    
    var persistedDeviceInfo: DeviceInfo? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: connectionConstants.connectionConfigPath)) else {
            return nil
        }
        return try? JSONDecoder().decode(DeviceInfo.self, from: data)
    }
    
    func resetDiskState() {
        connectionConstants.allPathURLs.forEach { url in
            if FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}
