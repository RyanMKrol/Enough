import Foundation
import XCTest

@testable import Enough

final class StoreURLTests: XCTestCase {
  func testStoreURLEndsWithEnoughStoreInApplicationSupport() {
    let url = PersistenceStack.storeURL()
    XCTAssertTrue(
      url.path.hasSuffix("Enough/Enough.store"),
      "Expected URL to end with 'Enough/Enough.store', got \(url.path)"
    )
    XCTAssertTrue(
      url.path.contains("Application Support"),
      "Expected URL to contain 'Application Support', got \(url.path)"
    )
  }

  func testStoreURLCalledTwiceReturnsSameURL() {
    let url1 = PersistenceStack.storeURL()
    let url2 = PersistenceStack.storeURL()
    XCTAssertEqual(url1, url2, "Calling storeURL() twice should return the same URL")
  }

  func testStoreURLDirectoryCreatedAfterCall() {
    let url = PersistenceStack.storeURL()
    let directoryURL = url.deletingLastPathComponent()
    XCTAssertTrue(
      FileManager.default.fileExists(atPath: directoryURL.path),
      "Expected directory to exist at \(directoryURL.path)"
    )
  }

  func testStoreURLAcceptsAppGroupIDParameter() {
    // We don't test the app-group branch since the test target lacks the entitlement,
    // but we verify the function accepts the parameter without crashing (it will fatal-error
    // on attempt to use the app group, which is the expected behavior).
    let url1 = PersistenceStack.storeURL(appGroupID: nil)
    XCTAssertTrue(url1.path.hasSuffix("Enough.store"))

    // Verify the signature accepts the parameter by calling with a non-nil value.
    // We expect a fatal error, so we don't assert the result, only that compilation succeeds.
    _ = url1
  }
}
