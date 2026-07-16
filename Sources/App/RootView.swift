import SwiftUI

/// Root of the app shell — switches on `AppState.phase`. Both branches are temporary
/// placeholders: onboarding is replaced by T031, main by T030.
struct RootView: View {
  let appState: AppState

  init(appState: AppState) {
    self.appState = appState
  }

  var body: some View {
    Group {
      switch appState.phase {
      case .onboarding:
        Text("Onboarding")
      case .main:
        MainShellView()
      }
    }
    .environment(\.accentTheme, appState.activeAccent)
  }
}
