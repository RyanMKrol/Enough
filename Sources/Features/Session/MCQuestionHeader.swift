import SwiftUI

struct MCQuestionHeader: View {
  @Environment(\.accentTheme) var accentTheme

  let target: String
  let pronunciation: String
  let onPlayAudio: () -> Void

  var body: some View {
    VStack(spacing: 14) {
      PulsingAudioButton(size: 60, isPulsing: true, action: onPlayAudio)

      Text(target)
        .font(.system(size: 34, weight: .bold))
        .foregroundStyle(EnoughColor.label)
        .multilineTextAlignment(.center)

      Text(pronunciation)
        .font(.system(size: 15, weight: .regular))
        .foregroundStyle(Color(hex: 0x6b6b70))

      Text("What does this mean?")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(EnoughColor.tertiaryText)
        .padding(.top, 6)
    }
  }
}

#Preview {
  ZStack {
    EnoughColor.canvas
      .ignoresSafeArea()

    MCQuestionHeader(
      target: "ありがとうございます",
      pronunciation: "arigatō gozaimasu",
      onPlayAudio: {}
    )
    .padding(20)
  }
}
