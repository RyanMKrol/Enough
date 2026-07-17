import XCTest

@testable import Enough

final class EnoughTests: XCTestCase {
  @MainActor
  func testAppStateConstructsFromPreviewServices() {
    let services = AppServices.preview()

    let appState = AppState(services: services)

    XCTAssertEqual(appState.phase, .onboarding)
  }
}
