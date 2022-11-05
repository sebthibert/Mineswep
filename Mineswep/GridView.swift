import SwiftUI

enum Difficulty: String, CaseIterable {
  case easy
  case hard

  var columnCount: Int {
    switch self {
    case .easy:
      return 7
    case .hard:
      return 18
    }
  }

  var rowCount: Int {
    switch self {
    case .easy:
      return 10
    case .hard:
      return 27
    }
  }

  var numberOfMines: Int {
    switch self {
    case .easy:
      return 8
    case .hard:
      return 99
    }
  }

  var numberOfTiles: Int {
    columnCount * rowCount
  }

  func touchingMineTiles(for tile: Int, mines: [Int]) -> Int {
    let touchingTilesSet = Set(touchingTiles(for: tile))
    let minesSet = Set(mines)
    return touchingTilesSet.intersection(minesSet).count
  }

  func touchingTiles(for tile: Int) -> [Int] {
//    switch self {
//    case .hard:
      if tile == 0 { // first row first column
        return [
          tile + 1,
          columnCount,
          columnCount + 1
        ]
      } else if tile == columnCount - 1 { // first row last column
        return [
          tile - 1,
          tile + columnCount - 1,
          tile + columnCount
        ]
      } else if tile == columnCount * (rowCount - 1) { // last row first column
        return [
          tile + 1,
          tile - columnCount,
          tile - columnCount - 1
        ]
      } else if tile == numberOfTiles - 1 { // last row last column
        return [
          tile - 1,
          tile - columnCount,
          tile - columnCount - 1
        ]
      } else if tile < columnCount { // first row middle columns
        return [
          tile - 1,
          tile + 1,
          tile + columnCount - 1,
          tile + columnCount,
          tile + columnCount + 1
        ]
      } else if tile % columnCount == 0 { // first column middle rows
        return [
          tile - columnCount,
          tile - columnCount + 1,
          tile + 1,
          tile + columnCount + 1,
          tile + columnCount
        ]
      } else if tile % columnCount == columnCount - 1 { // last column middle rows
        return [
          tile - columnCount,
          tile - columnCount - 1,
          tile - 1,
          tile + columnCount - 1,
          tile + columnCount
        ]
      } else if tile > ((rowCount - 1) * columnCount) { // last row middle columns
        return [
          tile - 1,
          tile - columnCount - 1,
          tile - columnCount,
          tile - columnCount + 1,
          tile + 1
        ]
      } else { // middles
        return [
          tile - columnCount - 1,
          tile - columnCount,
          tile - columnCount + 1,
          tile + 1,
          tile + columnCount + 1,
          tile + columnCount,
          tile + columnCount - 1,
          tile - 1
        ]
      }
//    }
  }
}

struct Game {
  let difficulty: Difficulty

  func mines() -> [Int] {
    var mines: [Int] = []
    var tiles = (0..<difficulty.numberOfTiles).map { $0 }
    (0..<difficulty.numberOfMines).forEach { _ in
      let tile = tiles.randomElement()
      if let tile, let index = tiles.firstIndex(of: tile) {
        tiles.remove(at: index)
        mines.append(tile)
      }
    }
    return mines.count == difficulty.numberOfMines ? mines : []
  }
}

struct GridView: View {
  private let difficulty: Difficulty
  @State var game: Game
  @State var mines: [Int]
  @State var selectedTiles: [Int] = []
  @State var flaggedTiles: [Int] = []
  @State var hasSelectedMine = false
  @State var hasWonGame = false

  init(difficulty: Difficulty) {
    self.difficulty = difficulty
    let game = Game(difficulty: difficulty)
    self.game = game
    self.mines = game.mines()
  }

  func resetGame() {
    let game = Game(difficulty: difficulty)
    self.game = game
    self.mines = game.mines()
    self.selectedTiles = []
    self.flaggedTiles = []
    self.hasSelectedMine = false
  }

  func recursiveZeroSelection(number: Int) {
    let isMine = mines.contains(number)
    let touchingMines = game.difficulty.touchingMineTiles(for: number, mines: mines)
    if isMine == false && touchingMines == 0 {
      let touchingTiles = game.difficulty.touchingTiles(for: number)
      touchingTiles.forEach { number in
        guard selectedTiles.contains(number) == false else {
          return
        }
        withAnimation {
          selectedTiles.append(number)
        }
        recursiveZeroSelection(number: number)
      }
    }
  }

  var body: some View {
    ScrollView([.horizontal, .vertical]) {
      ScrollView(.horizontal) {
        HStack {
          let columns = Array(repeating: GridItem(.fixed(44), spacing: 0), count: game.difficulty.columnCount)
          LazyVGrid(columns: columns, spacing: 0) {
            ForEach((0..<game.difficulty.numberOfTiles), id: \.self) { number in
              let touchingMines = game.difficulty.touchingMineTiles(for: number, mines: mines)
              let isMine = mines.contains(number)
              let isRevealed = selectedTiles.contains(number)
              let isFlagged = flaggedTiles.contains(number)
              Tile(
                touchingMines: touchingMines,
                isMine: isMine,
                isRevealed: isRevealed,
                isFlagged: isFlagged
              )
                .onTapGesture {
                  guard isRevealed == false else {
                    return
                  }
                  withAnimation {
                    selectedTiles.append(number)
                  }
                  guard isMine == false else {
                    hasSelectedMine = true
                    return
                  }
                  recursiveZeroSelection(number: number)
                  if selectedTiles.count == difficulty.numberOfTiles - difficulty.numberOfMines {
                    hasWonGame = true
                  }
                }
                .onLongPressGesture(perform: {
                  if let index = flaggedTiles.firstIndex(of: number) {
                    flaggedTiles.remove(at: index)
                  } else {
                    withAnimation {
                      flaggedTiles.append(number)
                    }
                  }
                }) { pressing in
                  print(pressing)
                }
            }
          }
          .border(.secondary, width: 2)
        }
        .padding()
        .alert("Game Over", isPresented: $hasSelectedMine) {
          Button("Restart", action: resetGame)
        }
        .alert("You win", isPresented: $hasWonGame) {
          Button("Restart", action: resetGame)
        }
      }
    }
  }
}

struct Tile: View {
  let touchingMines: Int
  let isMine: Bool
  let isRevealed: Bool
  let isFlagged: Bool

  var body: some View {
    ZStack {
      Rectangle()
        .frame(height: 44)
        .foregroundColor(isMine && isRevealed ? .red : isRevealed && touchingMines == 0 ? .secondary.opacity(0.3) : .clear)
      Image(systemName: "bolt.circle.fill")
        .resizable()
        .scaledToFit()
        .padding(8)
        .opacity(isRevealed && isMine ? 1 : 0)
      Text(touchingMines == 0 ? "" : String(touchingMines))
        .font(.title2.monospaced())
        .bold()
        .monospaced()
        .foregroundColor(touchingMines.color)
        .opacity(isRevealed && !isMine ? 1 : 0)
      Image(systemName: "flag.fill")
        .resizable()
        .scaledToFit()
        .foregroundColor(.red)
        .padding(8)
        .opacity(isFlagged ? 1 : 0)
        .scaleEffect(isFlagged ? 1 : 2)
        .offset(isFlagged ? .zero : CGSize(width: 0, height: -16))
    }
    .contentShape(Rectangle())
    .border(.secondary, width: 1)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    GridView(difficulty: .easy)
  }
}

extension Int {
  var color: Color {
    switch self {
    case 1:
      return .blue
    case 2:
      return .green
    case 3:
      return .red
    case 4:
      return .purple
    case 5:
      return .brown
    case 6:
      return .teal
    case 7:
      return .primary
    default:
      return .gray
    }
  }
}
