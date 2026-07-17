import Foundation

/// Top-level phase + active accent for the app shell. Onboarding vs. main is driven by
/// whether a trip is active; the phase itself is UI-only state — writing the
/// `TripProfileRecord` is the onboarding flow's job, not AppState's.
@Observable
final class AppState {
  enum Phase {
    case onboarding
    case main
  }

  /// A pending cross-screen action requested externally (e.g. an App Intent) that the shell
  /// and target tab observe and act on, then clear.
  enum AppAction: Equatable {
    case startReview
  }

  let services: AppServices
  var phase: Phase
  var activeAccent: AccentTheme
  /// Set by `startNewTrip()`, cleared on `completeOnboarding()` — lets the onboarding flow
  /// know to re-enter directly at the country picker instead of the first-launch welcome
  /// screen.
  var isReonboarding = false
  /// Set by `requestStartReview()`; consumed by `MainShellView` (switches tab) and
  /// `ReviewsTabView` (starts the session), then cleared by whoever consumes it.
  var pendingAction: AppAction?

  init(services: AppServices) {
    self.services = services
    let activeTrip = try? services.tripStore.activeTrip()
    if let trip = activeTrip.flatMap({ $0 }) {
      phase = .main
      activeAccent = AccentTheme(rawValue: trip.accentRawValue) ?? .japan
    } else {
      phase = .onboarding
      activeAccent = .japan
    }
  }

  /// Re-derives `phase`/`activeAccent` from the store — used after a debug/launch-argument
  /// seed writes a trip after `AppState` was already constructed.
  func refreshFromStore() {
    let activeTrip = try? services.tripStore.activeTrip()
    if let trip = activeTrip.flatMap({ $0 }) {
      phase = .main
      activeAccent = AccentTheme(rawValue: trip.accentRawValue) ?? .japan
    }
  }

  func completeOnboarding(accent: AccentTheme) {
    activeAccent = accent
    phase = .main
    isReonboarding = false
  }

  /// Ends the current trip and re-runs onboarding. Wipes learning progress (SRS + daily
  /// activity) but NEVER entitlements/purchases — owned packs must survive across trips.
  func startNewTrip() {
    try? services.tripStore.deactivateActiveTrip()
    try? services.cardSRSStore.reset()
    try? services.activityStore.reset()
    services.notifications.cancelAll()
    isReonboarding = true
    phase = .onboarding
  }

  /// Callable synchronously from the main actor (e.g. an App Intent) to switch the shell to
  /// the Reviews tab and start a review session via the existing StudyService path.
  func requestStartReview() {
    pendingAction = .startReview
  }
}
