#import <Foundation/Foundation.h>

//! Project version number for FKPortForwardingServer.
FOUNDATION_EXPORT double FKPortForwardingServerVersionNumber;

//! Project version string for FKPortForwardingServer.
FOUNDATION_EXPORT const unsigned char FKPortForwardingServerVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <FKPortForwardingServer/PublicHeader.h>


@interface FKPortForwardingServer : NSObject

- (instancetype)init;

- (void)listenForMultiplexingChannelOnPort:(NSUInteger)port;
- (void)forwardConnectionsFromPort:(NSUInteger)port;
- (void)close;

@end
