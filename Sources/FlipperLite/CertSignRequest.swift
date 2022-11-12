import Foundation
import CertUtils

struct CSR {
    /// Cert Sign Request
    /// - Parameters:
    ///   - csrFilePath: file path where the csr should be stored / retrieved from
    ///   - privateKeyFilePath: path where the private key should be stored.
    /// - Returns: Cert Sign Request file utf8 encoded string value.
    func getCSR(_ csrFilePath: String,
                privateKeyFilePath: String) -> String {
        let existingCSR = (try? String(contentsOfFile: csrFilePath, encoding: .utf8))
        if let existingCSR,
           !existingCSR.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return existingCSR
        }
        return generate(csrFilePath,
                        privateKeyFilePath: privateKeyFilePath)
    }
    
    private func generate(_ csrFilePath: String,
                          privateKeyFilePath: String) -> String {
        let result = CertUtilsWrapper.generateCertSigningRequest(Bundle.main.bundleIdentifier,
                                                                 csrFile: csrFilePath,
                                                                 privateKeyFile: privateKeyFilePath)
        if result {
            return (try? String(contentsOfFile: csrFilePath, encoding: .utf8)) ?? ""
        }
        return ""
    }
}
