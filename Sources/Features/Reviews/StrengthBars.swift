import SwiftUI

struct StrengthBars: View {
  let strength: Int

  var body: some View {
    HStack(spacing: 3) {
      ForEach(0..<3, id: \.self) { index in
        RoundedRectangle(cornerRadius: 2)
          .fill(index < strength ? EnoughColor.successGreen : Color(hex: 0xe5e5ea))
          .frame(width: 4, height: 14)
      }
    }
  }
}

#Preview {
  VStack(spacing: 16) {
    HStack {
      Text("Strength 0")
      Spacer()
      StrengthBars(strength: 0)
    }
    HStack {
      Text("Strength 1")
      Spacer()
      StrengthBars(strength: 1)
    }
    HStack {
      Text("Strength 2")
      Spacer()
      StrengthBars(strength: 2)
    }
    HStack {
      Text("Strength 3")
      Spacer()
      StrengthBars(strength: 3)
    }
  }
  .padding()
  .background(EnoughColor.canvas)
}
