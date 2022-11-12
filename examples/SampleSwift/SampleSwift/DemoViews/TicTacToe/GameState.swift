import Foundation
import Combine

struct GameState {
    let cells: [String]
    let turn : Player?
    let winner: Player?
    
    static var defaultState: GameState {
        .init(cells: Array(repeating: "", count: 9),
              turn: nil,
              winner: nil)
    }
}

extension GameState {
    static func state(from dict: [String: Any]) -> GameState {
        let cells = dict["cells"] as? [String] ?? []
        let turn = dict["turn"] as? String ?? ""
        let winner = dict["winner"] as? String ?? ""
        let activePlayer = Player(rawValue: turn)
        let winnerPlayer = Player(rawValue: winner)
        return .init(cells: cells,
                     turn: activePlayer,
                     winner: winnerPlayer)
    }
}
