import SwiftUI

private enum DemoType {
    case userDefaults
    case network
    case notifications
    case ticTacToe
    case logger
}

private struct Demo: Hashable {
    let title: String
    let type: DemoType
}

struct ContentView: View {
    private let demos: [Demo] = [
        Demo(title: "User Defaults Demo", type: .userDefaults),
        Demo(title: "Network Demo", type: .network),
        Demo(title: "Trigger Notifications Demo", type: .notifications),
        Demo(title: "Bi-directional Communication - Tic Tac Toe Demo", type: .ticTacToe),
        Demo(title: "RCLogger Demo", type: .logger),
    ]
    
    private let gameController: GameController
    
    init(gameController: GameController) {
        self.gameController = gameController
    }
    
    var body: some View {
        VStack {
            NavigationView {
                List(demos, id: \.self) { demo in
                    switch demo.type {
                    case .userDefaults:
                        NavigationLink(destination: UserDefaultsDemoView()) {
                            Text(demo.title)
                        }
                    case .network:
                        NavigationLink(destination: NetworkDemoView()) {
                            Text(demo.title)
                        }
                    case .notifications:
                        NavigationLink(destination: NotificationsDemoView()) {
                            Text(demo.title)
                        }
                    case .ticTacToe:
                        NavigationLink(destination: TicTacToeDemoView(gameController: gameController)) {
                            Text(demo.title)
                        }
                    case .logger:
                        NavigationLink(destination: LoggerDemoView()) {
                            Text(demo.title)
                        }
                    }
                }
                .navigationTitle("Select a demo")
            }
        }
    }
}
