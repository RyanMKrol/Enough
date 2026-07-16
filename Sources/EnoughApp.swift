import SwiftUI

@main
struct EnoughApp: App {
  @State private var services: AppServices
  @State private var appState: AppState

  init() {
    let services = AppServices.live()
    _services = State(initialValue: services)
    _appState = State(initialValue: AppState(services: services))
  }

  var body: some Scene {
    WindowGroup {
      RootView(appState: appState)
        .environment(\.services, services)
        .modelContainer(services.container)
    }
  }
}
