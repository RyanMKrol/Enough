import SwiftUI

struct ScenarioChip: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  @Environment(\.accentTheme) var accentTheme

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(
          isSelected ? accentTheme.accent : EnoughColor.secondaryText
        )
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
          Capsule()
            .fill(isSelected ? accentTheme.tint : EnoughColor.canvas)
        )
        .overlay(
          isSelected
            ? Capsule()
              .stroke(accentTheme.accent, lineWidth: 1.5)
              .padding(0.75)
            : nil
        )
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
  }
}

struct MetaChip: View {
  let text: String

  var body: some View {
    Text(text)
      .font(.system(size: 13, weight: .semibold))
      .foregroundColor(.white)
      .padding(.vertical, 5)
      .padding(.horizontal, 10)
      .background(
        Capsule()
          .fill(Color.white.opacity(0.25))
      )
  }
}

struct EyebrowLabel: View {
  let text: String

  init(_ text: String) {
    self.text = text
  }

  var body: some View {
    Text(text.uppercased())
      .font(EnoughFont.eyebrow())
      .foregroundColor(EnoughColor.tertiaryText)
      .tracking(12 * EnoughFont.eyebrowTracking)
  }
}

#Preview {
  VStack(spacing: 20) {
    VStack(alignment: .leading, spacing: 10) {
      EyebrowLabel("Step 1 of 3")
      HStack(spacing: 8) {
        ScenarioChip(title: "Eating out", isSelected: true) {}
        ScenarioChip(title: "Nightlife", isSelected: false) {}
      }
    }

    VStack(alignment: .leading, spacing: 12) {
      EyebrowLabel("Meta chips")
      HStack(spacing: 8) {
        MetaChip(text: "30 cards")
        MetaChip(text: "~12 min")
        MetaChip(text: "Audio")
      }
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(AccentTheme.japan.accent)
      )
    }

    Spacer()
  }
  .padding()
  .environment(\.accentTheme, .japan)
}
