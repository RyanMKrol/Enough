import SwiftData
import XCTest

@testable import Enough

final class AppStateTests: XCTestCase {
  @MainActor
  func testEmptyTripStoreStartsOnboardingWithJapanAccent() throws {
    let services = try makeServices()

    let appState = AppState(services: services)

    XCTAssertEqual(appState.phase, .onboarding)
    XCTAssertEqual(appState.activeAccent, .japan)
  }

  @MainActor
  func testActiveTripStartsMainWithMatchingAccent() throws {
    let services = try makeServices()
    try services.tripStore.saveNewTrip(
      countryId: "france",
      duration: "week",
      scenarioIds: [],
      accentRawValue: "france",
      startDate: Date()
    )

    let appState = AppState(services: services)

    XCTAssertEqual(appState.phase, .main)
    XCTAssertEqual(appState.activeAccent, .france)
  }

  @MainActor
  func testStartNewTripFlipsPhaseWithoutTouchingEntitlements() throws {
    let services = try makeServices()
    try services.entitlementStore.grant(productId: "japan-basics", kind: "deck", now: Date())
    try services.tripStore.saveNewTrip(
      countryId: "japan",
      duration: "weekend",
      scenarioIds: [],
      accentRawValue: "japan",
      startDate: Date()
    )

    let appState = AppState(services: services)
    XCTAssertEqual(appState.phase, .main)

    appState.startNewTrip()

    XCTAssertEqual(appState.phase, .onboarding)
    XCTAssertTrue(try services.entitlementStore.grantedProductIds().contains("japan-basics"))
  }

  @MainActor
  func testStartNewTripDeactivatesTripWipesProgressKeepsEntitlements() throws {
    let services = try makeServices()
    try services.entitlementStore.grant(productId: "japan-basics", kind: "deck", now: Date())
    try services.tripStore.saveNewTrip(
      countryId: "japan",
      duration: "weekend",
      scenarioIds: [],
      accentRawValue: "japan",
      startDate: Date()
    )
    try services.cardSRSStore.upsert(
      deckId: "japan-basics", cardId: "hello", statusRaw: "review", easeFactor: 2.3,
      intervalDays: 4, repetitions: 2, lapses: 0, dueAt: Date(), lastReviewedAt: Date()
    )
    try services.activityStore.addActivity(
      cardsReviewed: 3, cardsLearned: 1, seconds: 60, now: Date()
    )

    let appState = AppState(services: services)
    XCTAssertEqual(appState.phase, .main)

    appState.startNewTrip()

    XCTAssertEqual(appState.phase, .onboarding)
    XCTAssertNil(try services.tripStore.activeTrip())
    XCTAssertTrue(try services.cardSRSStore.records(forDeck: "japan-basics").isEmpty)
    XCTAssertTrue(try services.activityStore.all().isEmpty)
    XCTAssertTrue(try services.entitlementStore.grantedProductIds().contains("japan-basics"))
  }

  @MainActor
  private func makeServices() throws -> AppServices {
    AppServices.preview()
  }
}
