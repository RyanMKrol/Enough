import SwiftUI

struct SessionChrome: View {
  @Environment(\.accentTheme) var accentTheme

  let progress: Double
  let counterText: String
  let onClose: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Button(action: onClose) {
        Image(systemName: "xmark")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(Color(hex: 0x6b6b70))
          .frame(width: 30, height: 30)
          .background(Circle().fill(Color(hex: 0xf7f7fa)))
      }

      AnimatedProgressBar(
        progress: progress,
        tint: accentTheme.accent,
        trackColor: Color.black.opacity(0.08)
      )
      .frame(height: 4)

      Text(counterText)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(EnoughColor.tertiaryText)
        .frame(minWidth: 40, alignment: .trailing)
    }
  }
}

#Preview {
  SessionChrome(progress: 0.35, counterText: "3/12", onClose: {})
    .padding(20)
    .background(Color.white)
    .environment(\.accentTheme, .japan)
}
