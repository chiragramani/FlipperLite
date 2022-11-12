#ifndef CertUtilsWrapper_h
#define CertUtilsWrapper_h
#import <Foundation/Foundation.h>

@interface CertUtilsWrapper : NSObject

+ (BOOL)generateCertSigningRequest: (NSString*)appId
                           csrFile:(NSString*)csrFile
                    privateKeyFile:(NSString*)privateKeyFile;

+ (BOOL)generateCertPKCS12: (NSString*)caCertificateFile
           certificateFile:(NSString*)certificateFile
                   keyFile:(NSString*)keyFile
                pkcs12File:(NSString*)pkcs12File
                pkcs12Name:(NSString*)pkcs12Name
            pkcs12Password:(NSString*)pkcs12Password;
@end

#endif /* CertUtilsWrapper_h */
