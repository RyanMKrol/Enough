import SwiftUI

struct CountryCardView: View {
  let country: CountryInfo
  let isSelected: Bool
  let action: () -> Void

  private var accent: AccentTheme {
    AccentTheme(rawValue: country.accent) ?? .japan
  }

  var body: some View {
    Button(action: handleTap) {
      VStack(alignment: .leading, spacing: 12) {
        ZStack {
          RoundedRectangle(cornerRadius: 12)
            .fill(accent.tint)
            .frame(width: 46, height: 46)

          Text(country.flagEmoji)
            .font(.system(size: 28))
        }

        VStack(alignment: .leading, spacing: 2) {
          Text(country.name)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(EnoughColor.label)

          Text("\(country.nativeLanguageName) · \(country.decks.count) decks")
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(EnoughColor.secondaryText)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
      .background(EnoughColor.surface, in: RoundedRectangle(cornerRadius: 20))
      .overlay(
        RoundedRectangle(cornerRadius: 20)
          .stroke(
            isSelected ? accent.accent : Color.black.opacity(0.08),
            lineWidth: isSelected ? 2.5 : 1
          )
      )
      .shadow(
        color: isSelected ? accent.accent.opacity(0.25) : .clear,
        radius: isSelected ? 14 : 0,
        y: isSelected ? 6 : 0
      )
      .overlay(alignment: .topTrailing) {
        if isSelected {
          ZStack {
            Circle()
              .fill(accent.accent)
              .frame(width: 22, height: 22)

            Image(systemName: "checkmark")
              .font(.system(size: 11, weight: .bold))
              .foregroundColor(.white)
          }
          .offset(x: 8, y: -8)
        }
      }
      .animation(.spring(duration: 0.3), value: isSelected)
    }
    .buttonStyle(.plain)
  }

  private func handleTap() {
    if !isSelected {
      let generator = UIImpactFeedbackGenerator(style: .light)
      generator.impactOccurred()
    }
    action()
  }
}

#Preview {
  let country = CountryInfo(
    id: "japan", name: "Japan", languageName: "Japanese", nativeLanguageName: "日本語",
    accent: "japan", flagEmoji: "🇯🇵",
    decks: [
      DeckInfo(
        id: "d1", title: "Eating out", subtitle: "", scenario: "food", icon: "fork.knife",
        cardsFile: "d1.json", cardCount: 30, priceGBP: 1)
    ], bundles: [])

  return HStack(spacing: 12) {
    CountryCardView(country: country, isSelected: false, action: {})
    CountryCardView(country: country, isSelected: true, action: {})
  }
  .padding(22)
  .background(EnoughColor.surface)
}
