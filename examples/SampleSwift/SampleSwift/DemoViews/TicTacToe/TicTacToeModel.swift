import Foundation
import SwiftUI
import Combine

enum Player: String {
    case client = "X"
    case flipperDesktop = "O"
}

final class TicTacToeModel : ObservableObject {
    
    private let gameController: GameController
    
    @Published var squares = [Square]()
    @Published var gameOver = false
    @Published var displayMessage = "Seting up the environment..."
    
    private(set) var currentGameState: GameState = .defaultState
    
    private var cancellable: Cancellable?
    
    init(gameController: GameController) {
        self.gameController = gameController
        subcribeToGameState()
    }
    
    private func subcribeToGameState() {
        cancellable = gameController
            .gameState
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print(error)
                case .finished:
                    print("finished")
                }
            } receiveValue: { state in
                self.configureBoard(fromState: state)
            }
    }
    
    private func configureBoard(fromState state: GameState) {
        var newSquares = [Square]()
        state.cells.forEach { content in
            let squareStatus: SquareStatus
            if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                squareStatus = .empty
            } else if content == "O" {
                squareStatus = .visitor
            } else if content == "X" {
                squareStatus = .home
            } else {
                fatalError()
            }
            newSquares.append(Square(status: squareStatus))
        }
        squares = newSquares
        currentGameState = state
        if let _ = currentGameState.winner {
            displayMessage = currentGameState.winner == .client ? "You won 🎉" : "Flipper IDE won"
        } else if currentGameState.cells
            .filter({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty})
            .isEmpty {
            displayMessage = "Draw! Please restart the game from the Flipper IDE!"
        } else {
            displayMessage = currentGameState.turn == .client ? "Your turn..." : "Flipper IDE turn"
        }
    }
    
    func makeMove(index: Int, player: SquareStatus) {
        guard currentGameState.turn == .client,
              currentGameState.winner == nil,
              squares[index].squareStatus == .empty else {
            return
        }
        squares[index].squareStatus = player
        gameController.sendClosure?(index)
    }
}
