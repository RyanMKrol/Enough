import SwiftUI

@main
struct EnoughApp: App {
  @State private var services: AppServices
  @State private var appState: AppState

  init() {
    let services = AppServices.live()
    _services = State(initialValue: services)
    let newAppState = AppState(services: services)
    _appState = State(initialValue: newAppState)
    AppStatePublisher.shared.appState = newAppState
  }

  var body: some Scene {
    WindowGroup {
      RootView(appState: appState)
        .environment(\.services, services)
        .modelContainer(services.container)
    }
  }
}
