import SwiftData
import XCTest

@testable import Enough

final class OnboardingFlowTests: XCTestCase {
  @MainActor
  func testFinishWritesTripAndFlipsPhase() throws {
    let services = AppServices.preview()
    let appState = AppState(services: services)
    let draft = OnboardingDraft()

    draft.selectCountry(
      CountryInfo(
        id: "japan",
        name: "Japan",
        languageName: "Japanese",
        nativeLanguageName: "日本語",
        accent: "japan",
        flagEmoji: "🇯🇵",
        decks: [],
        bundles: []
      )
    )
    draft.duration = .weekend
    draft.scenarioIds = ["ordering-food", "asking-directions"]
    draft.selectedBundleId = "japan-weekend"
    draft.extraDeckIds = []

    try OnboardingCompleter.complete(draft: draft, services: services, appState: appState)

    let savedTrip = try services.tripStore.activeTrip()
    XCTAssertNotNil(savedTrip)
    XCTAssertEqual(savedTrip?.countryId, "japan")
    XCTAssertEqual(savedTrip?.duration, "weekend")
    XCTAssertEqual(
      Set(savedTrip?.scenarioIds ?? []),
      ["ordering-food", "asking-directions"]
    )
    XCTAssertEqual(savedTrip?.accentRawValue, "japan")
    XCTAssertTrue(savedTrip?.isActive ?? false)

    XCTAssertEqual(appState.phase, .main)
    XCTAssertEqual(appState.activeAccent, .japan)
  }

  @MainActor
  func testDraftAccentComputesFromCountry() throws {
    let draft = OnboardingDraft()

    draft.selectCountry(
      CountryInfo(
        id: "france",
        name: "France",
        languageName: "French",
        nativeLanguageName: "Français",
        accent: "france",
        flagEmoji: "🇫🇷",
        decks: [],
        bundles: []
      )
    )

    XCTAssertEqual(draft.accent, .france)
  }

  @MainActor
  func testDraftAccentDefaultsToJapan() {
    let draft = OnboardingDraft()

    XCTAssertEqual(draft.accent, .japan)
  }

  @MainActor
  func testSelectCountrySyncsBothFields() {
    let draft = OnboardingDraft()
    let country = CountryInfo(
      id: "germany",
      name: "Germany",
      languageName: "German",
      nativeLanguageName: "Deutsch",
      accent: "germany",
      flagEmoji: "🇩🇪",
      decks: [],
      bundles: []
    )

    draft.selectCountry(country)

    XCTAssertEqual(draft.selectedCountryId, "germany")
    XCTAssertEqual(draft.selectedCountry?.id, "germany")
    XCTAssertEqual(draft.accent, .germany)
  }
}
