#ifndef CertificateUtils_h
#define CertificateUtils_h

#ifdef __cplusplus
extern "C"
#endif

#include <openssl/pem.h>
#include <openssl/rsa.h>
#include <stdio.h>

namespace facebook {
namespace flipper {

bool generateCertSigningRequest(
                                const char* appId,
                                const char* csrFile,
                                const char* privateKeyFile);

bool generateCertPKCS12(
                        const char* caCertificateFile,
                        const char* certificateFile,
                        const char* keyFile,
                        const char* pkcs12File,
                        const char* pkcs12Name,
                        const char* pkcs12Password);

} // namespace flipper
} // namespace facebook


#endif /* CertificateUtils_h */
