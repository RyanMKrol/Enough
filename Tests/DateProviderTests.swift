import XCTest

@testable import Enough

@MainActor
class DateProviderTests: XCTestCase {
  private let suiteName = "DateProviderTests"

  override func tearDown() {
    super.tearDown()
    UserDefaults().removePersistentDomain(forName: suiteName)
  }

  func testSystemDateProviderNowIsCurrentDate() {
    let provider = SystemDateProvider()
    let now = Date()

    let interval = abs(provider.now.timeIntervalSince(now))
    XCTAssertLessThan(interval, 5)
  }

  func testAdjustableDateProviderFreshInstanceHasZeroOffset() {
    let userDefaults = UserDefaults(suiteName: suiteName)!
    let provider = AdjustableDateProvider(userDefaults: userDefaults)

    XCTAssertEqual(provider.dayOffset, 0)
  }

  func testAdjustableDateProviderFreshInstanceNowIsCurrentDate() {
    let userDefaults = UserDefaults(suiteName: suiteName)!
    let provider = AdjustableDateProvider(userDefaults: userDefaults)
    let now = Date()

    let interval = abs(provider.now.timeIntervalSince(now))
    XCTAssertLessThan(interval, 5)
  }

  func testAdjustableDateProviderPositiveOffset() {
    let userDefaults = UserDefaults(suiteName: suiteName)!
    let provider = AdjustableDateProvider(userDefaults: userDefaults)
    provider.dayOffset = 3

    let now = Date()
    let interval = provider.now.timeIntervalSince(now)
    let expectedInterval = 3 * 86_400.0

    XCTAssertEqual(interval, expectedInterval, accuracy: 5)
  }

  func testAdjustableDateProviderNegativeOffset() {
    let userDefaults = UserDefaults(suiteName: suiteName)!
    let provider = AdjustableDateProvider(userDefaults: userDefaults)
    provider.dayOffset = -2

    let now = Date()
    let interval = provider.now.timeIntervalSince(now)
    let expectedInterval = -2 * 86_400.0

    XCTAssertEqual(interval, expectedInterval, accuracy: 5)
  }

  func testAdjustableDateProviderPersistence() {
    let userDefaults = UserDefaults(suiteName: suiteName)!

    // Set offset on first instance
    let provider1 = AdjustableDateProvider(userDefaults: userDefaults)
    provider1.dayOffset = 5

    // Create second instance with same suite
    let provider2 = AdjustableDateProvider(userDefaults: userDefaults)

    XCTAssertEqual(provider2.dayOffset, 5)
    XCTAssertEqual(userDefaults.integer(forKey: "debug.dayOffset"), 5)
  }
}
