import SwiftUI

struct TicTacToeDemoView: View {
    @StateObject var ticTacToeModel: TicTacToeModel
    
    init(gameController: GameController) {
        let model = TicTacToeModel(gameController: gameController)
        _ticTacToeModel = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        VStack {
            Text("Tic Tac Toe with Flipper IDE")
                .bold()
                .foregroundColor(Color.black.opacity(0.7))
                .padding(.bottom)
                .font(.title2)
            Text(ticTacToeModel.displayMessage)
            if !ticTacToeModel.squares.isEmpty {
                ForEach(0 ..< ticTacToeModel.squares.count / 3,
                        content: { row in
                    HStack {
                        ForEach(0 ..< 3, content: {
                            column in
                            let index = row * 3 + column
                            SquareView(dataSource: ticTacToeModel.squares[index],
                                       action: {
                                self.buttonAction(index)
                            })
                        })
                    }
                })
            }
            Spacer()
        }
    }
    
    private func buttonAction(_ index : Int) {
        ticTacToeModel.makeMove(index: index,
                                player: .home)
    }
}
