#import "CertUtilsWrapper.h"
#import <Foundation/Foundation.h>
#import "CertificateUtils.h"

@implementation CertUtilsWrapper

+ (BOOL)generateCertSigningRequest: (NSString*)appId
                           csrFile:(NSString*)csrFile
                    privateKeyFile:(NSString*)privateKeyFile {
    return facebook::flipper::generateCertSigningRequest(
                                                         [appId cStringUsingEncoding: NSUTF8StringEncoding],
                                                         [csrFile cStringUsingEncoding: NSUTF8StringEncoding],
                                                         [privateKeyFile cStringUsingEncoding: NSUTF8StringEncoding]
                                                         );
    
}

+ (BOOL)generateCertPKCS12: (NSString*)caCertificateFile
           certificateFile:(NSString*)certificateFile
                   keyFile:(NSString*)keyFile
                pkcs12File:(NSString*)pkcs12File
                pkcs12Name:(NSString*)pkcs12Name
            pkcs12Password:(NSString*)pkcs12Password {
    return facebook::flipper::generateCertPKCS12(
                                                 [caCertificateFile cStringUsingEncoding: NSUTF8StringEncoding],
                                                 [certificateFile cStringUsingEncoding: NSUTF8StringEncoding],
                                                 [keyFile cStringUsingEncoding: NSUTF8StringEncoding],
                                                 [pkcs12File cStringUsingEncoding: NSUTF8StringEncoding],
                                                 [pkcs12Name cStringUsingEncoding: NSUTF8StringEncoding],
                                                 [pkcs12Password cStringUsingEncoding: NSUTF8StringEncoding]
                                                 );
    
}

@end
