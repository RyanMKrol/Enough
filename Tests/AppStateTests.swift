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
  func testRequestStartReviewSetsPendingStartReviewAction() throws {
    let services = try makeServices()
    let appState = AppState(services: services)

    XCTAssertNil(appState.pendingAction)

    appState.requestStartReview()

    XCTAssertEqual(appState.pendingAction, .startReview)
  }

  @MainActor
  func testPendingStartReviewCanDriveMakeReviewSession() throws {
    let services = try makeServices()
    try services.tripStore.saveNewTrip(
      countryId: "japan",
      duration: "weekend",
      scenarioIds: [],
      accentRawValue: "japan",
      startDate: Date()
    )
    try services.entitlementStore.grant(productId: "japan-basics", kind: "deck", now: Date())

    let appState = AppState(services: services)
    appState.requestStartReview()

    XCTAssertEqual(appState.pendingAction, .startReview)
    XCTAssertNoThrow(try appState.services.study.makeReviewSession())
  }

  @MainActor
  private func makeServices() throws -> AppServices {
    AppServices.preview()
  }
}
