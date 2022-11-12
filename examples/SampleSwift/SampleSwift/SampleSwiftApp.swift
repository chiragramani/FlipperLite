import SwiftUI
import FlipperLite

@main
struct SampleSwiftApp: App {
    private let gameController = GameController()
    
    init() {
        try? FlipperClient.shared.addPlugin(RCLoggerPlugin())
        try? FlipperClient.shared.addPlugin(NetworkPlugin(networkAdapter: FlipperNetworkAdapter()))
        try? FlipperClient.shared.addPlugin(UserDefaultsPlugin(suiteName: nil))
        try? FlipperClient.shared.addPlugin(TicTacToePlugin(gameController: gameController))
        try? FlipperClient.shared.addPlugin(ExamplePlugin.shared)
        FlipperClient.shared.connectToFlipper()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(gameController: gameController)
        }
    }
}
