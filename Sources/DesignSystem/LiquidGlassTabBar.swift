import SwiftUI

struct LiquidGlassTabBar: View {
  @Binding var selection: EnoughTab
  @Environment(\.accentTheme) var accentTheme

  var body: some View {
    HStack(spacing: 0) {
      ForEach(EnoughTab.allCases) { tab in
        Button(
          action: {
            selection = tab
            hapticFeedback()
          },
          label: {
            VStack(spacing: 4) {
              Image(systemName: tab.symbol)
                .font(.system(size: 18, weight: .semibold))
              Text(tab.title)
                .font(.system(size: 10, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 58)
            .foregroundStyle(
              selection == tab ? accentTheme.accent : EnoughColor.inactiveTab
            )
          }
        )
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier(tab.axID)
      }
    }
    .frame(maxWidth: .infinity)
    .frame(minHeight: 58)
    .padding(.vertical, 10)
    .background {
      Capsule()
        .fill(.ultraThinMaterial)
        .overlay(Color.white.opacity(0.55))
    }
    .overlay {
      Capsule()
        .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
    }
    .shadow(color: .black.opacity(0.1), radius: 22, y: 6)
    .sensoryFeedback(.impact(weight: .light), trigger: selection)
  }

  private func hapticFeedback() {
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
  }
}

#Preview {
  @Previewable @State var selection: EnoughTab = .learn
  VStack {
    Spacer()
    LiquidGlassTabBar(selection: $selection)
      .padding(.horizontal, 44)
      .padding(.bottom, 18)
  }
  .background(EnoughColor.canvas)
  .environment(\.accentTheme, .japan)
}
