import SwiftUI

enum DeckRowStatus: Equatable {
  case learned
  case progress(Int, Int)
  case new
}

struct DeckListRow: View {
  let iconSystemName: String
  let title: String
  let progress: Double
  let status: DeckRowStatus

  @Environment(\.accentTheme) var accentTheme

  var body: some View {
    HStack(spacing: 12) {
      RoundedRectangle(cornerRadius: 10)
        .fill(accentTheme.tint)
        .frame(width: 34, height: 34)
        .overlay(
          Image(systemName: iconSystemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(accentTheme.accent)
        )

      VStack(alignment: .leading, spacing: 5) {
        Text(title)
          .font(.system(size: 17, weight: .regular))
          .foregroundColor(EnoughColor.label)

        AnimatedProgressBar(
          progress: progress,
          tint: progressBarTint,
          trackColor: Color.black.opacity(0.08)
        )
        .frame(height: 4)
      }

      Spacer()

      statusView
    }
    .padding(.vertical, 12)
  }

  @ViewBuilder
  var statusView: some View {
    switch status {
    case .learned:
      HStack(spacing: 4) {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 15, weight: .semibold))
          .foregroundColor(EnoughColor.successGreen)

        Text("Learned")
          .font(.system(size: 13, weight: .semibold))
          .foregroundColor(EnoughColor.successDeep)
      }
    case .progress(let current, let total):
      Text("\(current)/\(total)")
        .font(.system(size: 15, weight: .regular))
        .foregroundColor(EnoughColor.secondaryText)
    case .new:
      Text("New")
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(EnoughColor.secondaryText)
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(Capsule().fill(EnoughColor.insetSurface))
    }
  }

  var progressBarTint: Color {
    status == .learned ? EnoughColor.successGreen : accentTheme.accent
  }
}

#Preview {
  VStack(spacing: 0) {
    DeckListRow(
      iconSystemName: "leaf.fill",
      title: "Japanese Basics",
      progress: 1.0,
      status: .learned
    )
    .padding(.horizontal, 16)

    Divider()
      .padding(.leading, 62)

    DeckListRow(
      iconSystemName: "fork.knife",
      title: "Eating Out",
      progress: 0.27,
      status: .progress(8, 30)
    )
    .padding(.horizontal, 16)

    Divider()
      .padding(.leading, 62)

    DeckListRow(
      iconSystemName: "map",
      title: "Getting Around",
      progress: 0.0,
      status: .new
    )
    .padding(.horizontal, 16)

    Spacer()
  }
  .frame(maxHeight: .infinity, alignment: .top)
  .background(EnoughColor.canvas)
  .environment(\.accentTheme, .japan)
}
