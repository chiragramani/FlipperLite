import Foundation

struct ConnectionConstants {
    let csrFilePath: String
    let caCertFilePath: String
    let clientCertFilePath: String
    let privateKeyFilePath: String
    let mainCertFileNamePath: String
    let connectionConfigPath: String
    
    init(sonarDirectoryURL: URL) {
        self.csrFilePath = sonarDirectoryURL.appendingPathComponent("app.csr").path
        self.caCertFilePath = sonarDirectoryURL.appendingPathComponent("sonarCA.crt").path
        self.clientCertFilePath = sonarDirectoryURL.appendingPathComponent("device.crt").path
        self.privateKeyFilePath = sonarDirectoryURL.appendingPathComponent("privateKey.pem").path
        self.mainCertFileNamePath = sonarDirectoryURL.appendingPathComponent("device.p12").path
        self.connectionConfigPath = sonarDirectoryURL.appendingPathComponent("connection_config.json").path
    }
    
    var allPathURLs: [URL] {
        [
            csrFilePath,
            caCertFilePath,
            clientCertFilePath,
            privateKeyFilePath,
            mainCertFileNamePath,
            connectionConfigPath
        ].map {
            URL(fileURLWithPath: $0)
        }
    }
}
