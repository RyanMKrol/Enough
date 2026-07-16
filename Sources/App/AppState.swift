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

  var phase: Phase
  var activeAccent: AccentTheme

  init(services: AppServices) {
    let activeTrip = try? services.tripStore.activeTrip()
    if let trip = activeTrip.flatMap({ $0 }) {
      phase = .main
      activeAccent = AccentTheme(rawValue: trip.accentRawValue) ?? .japan
    } else {
      phase = .onboarding
      activeAccent = .japan
    }
  }

  func completeOnboarding(accent: AccentTheme) {
    activeAccent = accent
    phase = .main
  }

  func startNewTrip() {
    phase = .onboarding
  }
}
