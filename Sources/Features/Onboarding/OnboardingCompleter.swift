import Foundation

enum OnboardingCompleter {
  static func complete(
    draft: OnboardingDraft,
    services: AppServices,
    appState: AppState
  ) throws {
    let countryId = draft.selectedCountryId ?? "japan"
    _ = try services.tripStore.saveNewTrip(
      countryId: countryId,
      duration: draft.duration.rawValue,
      scenarioIds: Array(draft.scenarioIds),
      accentRawValue: draft.accent.rawValue,
      startDate: services.dateProvider.now
    )
    appState.completeOnboarding(accent: draft.accent)
  }
}
