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
            .contentShape(Rectangle())
            .foregroundStyle(
              selection == tab ? accentTheme.accent : EnoughColor.inactiveTab
            )
          }
        )
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier(tab.axID)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(selection == tab ? .isSelected : [])
      }
    }
    .frame(maxWidth: .infinity)
    .frame(minHeight: 58)
    .padding(.vertical, 10)
    .glassEffect(.regular, in: Capsule())
    .shadow(color: .black.opacity(0.1), radius: 22, y: 6)
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
