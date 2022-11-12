import Foundation
import CertUtils

final class FlipperConnectTask {
    private let sonarDirectoryURL: URL
    private let connectionConstants: ConnectionConstants
    private let connectionConfig: FlipperConnectionConfig
    private let connectionState: FlipperConnectionState
    private var authHandler: FlipperWebSocketAuthHandler?
    
    init(sonarDirectoryURL: URL,
         connectionConstants: ConnectionConstants,
         connectionConfig: FlipperConnectionConfig,
         connectionState: FlipperConnectionState) {
        self.connectionConfig = connectionConfig
        self.sonarDirectoryURL = sonarDirectoryURL
        self.connectionConstants = connectionConstants
        self.connectionState = connectionState
    }
    
    var onError: ((Error?) -> ())?
    var onInit: ((URLSessionWebSocketTask) -> Void)?
    
    func connect() throws {
        guard let url = getConnectURL() else {
            throw FlipperError.invalidURL(urlString,
                                          queryItems())
        }
        let urlRequest = URLRequest(url: url)
        let websocketTask = connectionConfig.urlSession.webSocketTask(with: urlRequest)
        onInit?(websocketTask)
        if connectionState.isSecure {
            authHandler = FlipperWebSocketAuthHandler(connectionConstants: connectionConstants)
            if #available(iOS 15.0, *) {
                websocketTask.delegate = authHandler
                websocketTask.resume()
            } else {
                FlipperLogger.logError("This package only supports iOS 15 and above.")
                onError?(FlipperError.requireMinVersioniOS15)
            }
        } else {
            websocketTask.resume()
        }
        if !connectionState.isSecure {
            try sendSignCertMessage(websocketTask: websocketTask)
        }
    }
    
    private func sendSignCertMessage(websocketTask: URLSessionWebSocketTask) throws {
        var messageDict = [String: Any]()
        messageDict["medium"] = 1
        messageDict["destination"] = sonarDirectoryURL.path + "/"
        messageDict["csr"] = CSR().getCSR(connectionConstants.csrFilePath,
                                          privateKeyFilePath: connectionConstants.privateKeyFilePath)
        messageDict["method"] = "signCertificate"
        let jsonData = try JSONSerialization.data(withJSONObject: messageDict,
                                                  options: [])
        let stringifiedJSON = String(data: jsonData,
                                     encoding: .utf8) ?? ""
        let message = URLSessionWebSocketTask.Message.string(stringifiedJSON)
        websocketTask.send(message) { [weak self] error in
            self?.onError?(error)
        }
    }
    
    private func getConnectURL() -> URL? {
        var components = URLComponents(string: urlString)
        components?.queryItems = queryItems()
        return components?.url
    }
    
    private func queryItems() -> [URLQueryItem] {
        if case let (.secure(deviceInfo)) = connectionState {
            return connectionConfig.queryItems(deviceID: deviceInfo.deviceId,
                                               csrPath: sonarDirectoryURL.path + "/")
        } else {
            return connectionConfig.queryItems()
        }
    }
    
    private var urlString: String {
        connectionState.isSecure ? Self.secureURLString : Self.unsecureURLString
    }
    
    private static let secureURLString = "wss://localhost:\(FlipperEnvironmentVariables.getSecurePort())"
    private static let unsecureURLString = "ws://localhost:\(FlipperEnvironmentVariables.getInsecurePort())"
}
