import SwiftUI

/// Root of the app shell — switches on `AppState.phase`. Both branches are temporary
/// placeholders: onboarding is replaced by T031, main by T030.
struct RootView: View {
  let appState: AppState

  @Environment(\.scenePhase) private var scenePhase

  init(appState: AppState) {
    self.appState = appState
    LaunchArguments.handle(services: appState.services)
    appState.refreshFromStore()
  }

  var body: some View {
    Group {
      switch appState.phase {
      case .onboarding:
        OnboardingFlowView(appState: appState, startAtCountryPicker: appState.isReonboarding)
      case .main:
        MainShellView()
      }
    }
    .environment(appState)
    .environment(\.accentTheme, appState.activeAccent)
    .onChange(of: scenePhase) { _, newPhase in
      guard newPhase == .active, appState.phase == .main else { return }
      Task {
        await appState.services.notifications.rescheduleAfterActivity(services: appState.services)
      }
    }
  }
}
