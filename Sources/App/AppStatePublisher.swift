import Foundation

@MainActor
final class AppStatePublisher {
  static let shared = AppStatePublisher()

  var appState: AppState?

  private init() {}
}
