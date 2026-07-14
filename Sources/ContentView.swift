import SwiftUI

struct ContentView: View {
  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "globe")
        .font(.system(size: 48))
      Text("Enough")
        .font(.largeTitle.bold())
      Text("Just enough of a language for your trip.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .padding()
  }
}

#Preview {
  ContentView()
}
