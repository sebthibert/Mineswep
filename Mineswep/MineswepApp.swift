import SwiftUI

@main
struct MineswepApp: App {
  @State var isSettingsPresented = false
  @State var difficulty: Difficulty = .easy

  var body: some Scene {
    WindowGroup {
      VStack(spacing: 0) {
        HStack {
          Button {
            isSettingsPresented = true
          } label: {
            Image(systemName: "house")
          }
          Spacer()
        }
        .padding()
        GridView(difficulty: difficulty)
      }
      .popover(isPresented: $isSettingsPresented) {
        VStack(spacing: 16) {
          ForEach(Difficulty.allCases, id: \.self) { difficulty in
            Button(difficulty.rawValue.capitalized) {
              self.difficulty = difficulty
            }
            .buttonStyle(.bordered)
          }
        }
      }
    }
  }
}
