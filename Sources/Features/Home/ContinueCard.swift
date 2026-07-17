import SwiftUI

struct ContinueCard: View {
  let deckName: String
  let detailLine: String
  let progress: Double
  let onPlay: () -> Void

  @Environment(\.accentTheme) var accentTheme

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 14) {
        ProgressRing(
          progress: progress,
          size: 64,
          lineWidth: 6,
          tint: accentTheme.accent,
          showsPercent: true
        )

        VStack(alignment: .leading, spacing: 4) {
          EyebrowLabel("Continue")

          Text(deckName)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(EnoughColor.label)

          Text(detailLine)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(EnoughColor.secondaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
        }
        .layoutPriority(1)

        Spacer()

        Button(action: onPlay) {
          Image(systemName: "play.fill")
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
        }
        .frame(width: 44, height: 44)
        .background(Circle().fill(accentTheme.accent))
        .accessibilityLabel("Continue learning")
      }
      .padding(18)
    }
    .background(
      LinearGradient(
        gradient: Gradient(
          colors: [
            accentTheme.tint,
            accentTheme.tint.opacity(0.55),  // swiftlint:disable:this trailing_comma
          ]
        ),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .cornerRadius(24)
    .onTapGesture {
      onPlay()
    }
  }
}

#Preview {
  VStack(spacing: 16) {
    ContinueCard(
      deckName: "Japanese Basics",
      detailLine: "8 of 30 cards · about 6 min left",
      progress: 0.27,
      onPlay: {}
    )
    .padding()
  }
  .frame(maxHeight: .infinity, alignment: .top)
  .background(EnoughColor.canvas)
  .environment(\.accentTheme, .japan)
}
