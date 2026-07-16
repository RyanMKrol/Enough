import SwiftUI

struct MainShellView: View {
  @State private var selection: EnoughTab = .learn

  var body: some View {
    ZStack(alignment: .bottom) {
      ForEach(EnoughTab.allCases) { tab in
        screen(for: tab)
          .opacity(selection == tab ? 1 : 0)
          .allowsHitTesting(selection == tab)
          .environment(\.isTabActive, selection == tab)
      }

      LiquidGlassTabBar(selection: $selection)
        .padding(.horizontal, 44)
        .padding(.bottom, 18)
    }
    .background(EnoughColor.canvas)
  }

  @ViewBuilder
  private func screen(for tab: EnoughTab) -> some View {
    switch tab {
    case .learn:
      HomeView()
    default:
      ZStack {
        EnoughColor.canvas.ignoresSafeArea()
        Text(tab.title)
          .font(EnoughFont.largeTitle())
          .foregroundStyle(EnoughColor.label)
      }
    }
  }
}

#Preview {
  MainShellView()
    .environment(\.accentTheme, .japan)
}
