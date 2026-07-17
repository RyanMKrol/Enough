import AppIntents
import XCTest

@testable import Enough

final class StartReviewIntentTests: XCTestCase {
  @MainActor
  func testStartReviewIntentCallsRequestStartReview() async throws {
    let services = try makeServices()
    let appState = AppState(services: services)
    AppStatePublisher.shared.appState = appState

    let intent = StartReviewIntent()
    _ = try await intent.perform()

    XCTAssertEqual(appState.pendingAction, .startReview)
  }

  @MainActor
  func testStartReviewIntentThrowsWhenAppStateUnavailable() async throws {
    AppStatePublisher.shared.appState = nil

    let intent = StartReviewIntent()

    do {
      _ = try await intent.perform()
      XCTFail("Expected intent to throw")
    } catch let error as StartReviewIntent.IntentError {
      XCTAssertEqual(error, .appStateNotAvailable)
    }
  }

  @MainActor
  private func makeServices() throws -> AppServices {
    AppServices.preview()
  }
}
