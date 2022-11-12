import Foundation
import CertUtils

final class FlipperWebSocketAuthHandler: NSObject, URLSessionTaskDelegate {
    private let connectionConstants: ConnectionConstants
    private let password = "fl1pp3r"
    
    init(connectionConstants: ConnectionConstants) {
        self.connectionConstants = connectionConstants
    }
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            // https://gist.github.com/lihnux/8bcc4c256a0b3b17af23
            var result: SecTrustResultType = .init(rawValue: 0)!
            SecTrustEvaluate(challenge.protectionSpace.serverTrust!, &result)
            switch result {
            case .deny, .fatalTrustFailure, .invalid, .otherError, .unspecified:
                completionHandler(.cancelAuthenticationChallenge, nil)
            default:
                completionHandler(.useCredential,
                                  .init(trust: challenge.protectionSpace.serverTrust!))
            }
        } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
            if let deviceCert = getDeviceCertificate() {
                let result = provideUrlSessionDispostionWithPKCS12Data(data: deviceCert)
                completionHandler(result.0, result.1)
            } else {
                completionHandler(.rejectProtectionSpace, nil)
            }
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    private func provideUrlSessionDispostionWithPKCS12Data(data: Data) -> (
        URLSession.AuthChallengeDisposition,
        URLCredential
    ){
        let pcks12Data:CFData = data as CFData
        let options = [ kSecImportExportPassphrase as String: password ]
        
        var rawItems: CFArray?
        let status = SecPKCS12Import(pcks12Data, options as CFDictionary, &rawItems)
        
        precondition(status == errSecSuccess)
        
        let items = rawItems! as! Array<Dictionary<String, Any>>
        
        precondition(items.count == 1)
        
        let firstItem = items[0]
        let identity = firstItem[kSecImportItemIdentity as String] as! SecIdentity?
        
        
        let disposition: URLSession.AuthChallengeDisposition = .useCredential
        let creds = URLCredential(identity: identity!,
                                  certificates: nil,
                                  persistence: .forSession)
        
        return (disposition,creds)
    }
    
    private func getDeviceCertificate() -> Data? {
        if FileManager.default.fileExists(atPath: connectionConstants.mainCertFileNamePath) {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: connectionConstants.mainCertFileNamePath))
        }
        let result = CertUtilsWrapper.generateCertPKCS12(
            connectionConstants.caCertFilePath,
            certificateFile: connectionConstants.clientCertFilePath,
            keyFile: connectionConstants.privateKeyFilePath,
            pkcs12File: connectionConstants.mainCertFileNamePath,
            pkcs12Name: "device.p12",
            pkcs12Password: password
        )
        guard result else {
            FlipperLogger.logError("couldn't satisfy auth constraints as CertPKCS12 generation failed")
            return nil
        }
        if let data = try? Data(contentsOf: URL(fileURLWithPath:  connectionConstants.mainCertFileNamePath)) {
            return data
        }
        FlipperLogger.logError("couldn't construct data for file at path: \(connectionConstants.mainCertFileNamePath)")
        return nil
    }
}
