import SwiftUI

enum PackRowState {
  case inBundle(bundleName: String)
  case extra(priceLabel: String)
  case available(priceLabel: String)
}

struct PackChecklistRow: View {
  let name: String
  let cardCount: Int
  let state: PackRowState
  let onToggle: (() -> Void)?

  @Environment(\.accentTheme) var accentTheme

  var body: some View {
    if let onToggle {
      Button(action: handleTap) {
        content
      }
      .buttonStyle(.plain)
    } else {
      content
    }
  }

  @ViewBuilder
  private var content: some View {
    HStack(spacing: 12) {
      indicator
        .frame(width: 22, height: 22)

      VStack(alignment: .leading, spacing: 2) {
        Text(name)
          .font(.system(size: 16, weight: .regular))
          .foregroundColor(EnoughColor.label)

        Text("\(cardCount) cards")
          .font(.system(size: 13, weight: .regular))
          .foregroundColor(EnoughColor.tertiaryText)
      }

      Spacer()

      trailingContent
    }
    .frame(minHeight: 52)
  }

  @ViewBuilder
  private var indicator: some View {
    switch state {
    case .inBundle, .extra:
      ZStack {
        Circle()
          .fill(accentTheme.accent)

        Image(systemName: "checkmark")
          .font(.system(size: 11, weight: .bold))
          .foregroundColor(.white)
      }

    case .available:
      Circle()
        .stroke(Color(hex: 0xc7c7cc), lineWidth: 1.5)
    }
  }

  @ViewBuilder
  private var trailingContent: some View {
    switch state {
    case .inBundle(let bundleName):
      Text(bundleName)
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(accentTheme.accent)

    case .extra(let priceLabel):
      Text(priceLabel)
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(accentTheme.accent)

    case .available(let priceLabel):
      Text(priceLabel)
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(EnoughColor.secondaryText)
    }
  }

  private func handleTap() {
    onToggle?()
  }
}

#Preview {
  VStack(spacing: 0) {
    PackChecklistRow(
      name: "Eating out",
      cardCount: 30,
      state: .inBundle(bundleName: "Weekend"),
      onToggle: nil
    )

    Divider()
      .padding(.leading, 49)

    PackChecklistRow(
      name: "Getting around",
      cardCount: 25,
      state: .extra(priceLabel: "+ £1"),
      onToggle: {}
    )

    Divider()
      .padding(.leading, 49)

    PackChecklistRow(
      name: "Shopping",
      cardCount: 28,
      state: .available(priceLabel: "+ £1"),
      onToggle: {}
    )
  }
  .padding(.horizontal, 18)
  .padding(.vertical, 12)
  .background(EnoughColor.surface)
  .environment(\.accentTheme, .japan)
}
