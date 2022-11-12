import Foundation
import FKPortForwardingServer

final class FlipperPortForwarder {
    private var _secureServer: FKPortForwardingServer?
    private var _insecureServer: FKPortForwardingServer?
    
    func setup() {
        guard eligibleForPortForwarding, _secureServer == nil || _insecureServer == nil else { return }
        _secureServer = FKPortForwardingServer()
        _secureServer?.forwardConnections(fromPort: UInt(FlipperEnvironmentVariables.getSecurePort()))
        _secureServer?.listenForMultiplexingChannel(onPort: 9078)
        
        _insecureServer = FKPortForwardingServer()
        _insecureServer?.forwardConnections(fromPort: UInt(FlipperEnvironmentVariables.getInsecurePort()))
        _insecureServer?.listenForMultiplexingChannel(onPort: 9079)
    }
    
    func reset() {
        guard eligibleForPortForwarding else { return }
        _secureServer?.close()
        _secureServer = nil
    
        _insecureServer?.close()
        _insecureServer = nil
    }
    
    private var eligibleForPortForwarding: Bool {
        #if !TARGET_OS_OSX && !TARGET_OS_SIMULATOR && !TARGET_OS_MACCATALYST
            return true
        #else
            return false
        #endif
    }
}
