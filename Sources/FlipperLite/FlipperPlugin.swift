import Foundation

public protocol FlipperPlugin {
    /**
     * The id of this plugin. This is the namespace which Flipper desktop plugins will call
     * methods on to route them to your plugin. This should match the id specified in your React
     * plugin.
     */
    var id: String { get }
    
    /**
     * Called when a connection has been established. The connection passed to this method is valid
     * until {`FliperPlugin#didDisconnect()`} is called.
     *
     * Only called once if the plugin runs in Background.
     */
    func didConnect(connection: FlipperConnection)
    
    /**
     * Called when the connection passed to `FlipperPlugin#didConnect(FlipperConnection)` is no
     * longer valid. Do not try to use the connection in or after this method has been called.
     */
    func didDisconnect()
    
    /**
     * Returns true if the plugin is meant to be run in background too, otherwise it returns false.
     */
    var runInBackground: Bool { get }
}
