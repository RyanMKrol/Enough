import SwiftData
import XCTest

@testable import Enough

@MainActor
class TimeTravelTests: XCTestCase {
  private let suiteName = "TimeTravelTests"

  override func tearDown() {
    super.tearDown()
    UserDefaults().removePersistentDomain(forName: suiteName)
  }

  private func makeTestAppServices(
    with provider: AdjustableDateProvider
  ) -> AppServices {
    // swiftlint:disable:next force_try
    let container = try! PersistenceStack.container(inMemory: true)
    let ctx = ModelContext(container)
    return AppServices(
      dateProvider: provider,
      contentStore: .init(),
      container: container,
      tripStore: .init(context: ctx),
      entitlementStore: .init(context: ctx),
      cardSRSStore: .init(context: ctx),
      activityStore: .init(context: ctx),
      purchase: StubPurchaseService(entitlements: .init(context: ctx), catalog: nil),
      audio: .init(content: .init()),
      study: .init(
        content: .init(),
        srsStore: .init(context: ctx),
        activityStore: .init(context: ctx),
        entitlements: .init(context: ctx),
        dateProvider: provider
      ),
      deckProgress: .init(
        content: .init(),
        srsStore: .init(context: ctx),
        entitlements: .init(context: ctx),
        dateProvider: provider
      ),
      stats: .init(activityStore: .init(context: ctx), dateProvider: provider),
      notifications: .init(center: NoopNotificationCenter())
    )
  }

  func testTimeTravelOffsetReturnsNilWhenProviderNotAdjustable() {
    let services = AppServices.preview()
    let offset = TimeTravel.offset(in: services)
    XCTAssertNotNil(offset)
  }

  func testTimeTravelOffsetReturnsCurrentValue() {
    let userDefaults = UserDefaults(suiteName: suiteName)!
    let provider = AdjustableDateProvider(userDefaults: userDefaults)
    provider.dayOffset = 3

    let services = makeTestAppServices(with: provider)
    let offset = TimeTravel.offset(in: services)
    XCTAssertEqual(offset, 3)
  }

  func testTimeTravelSetOffsetUpdatesProvider() {
    let userDefaults = UserDefaults(suiteName: suiteName)!
    let provider = AdjustableDateProvider(userDefaults: userDefaults)
    let services = makeTestAppServices(with: provider)

    TimeTravel.setOffset(5, in: services)
    XCTAssertEqual(TimeTravel.offset(in: services), 5)
  }

  func testTimeTravelPositiveOffsetMovesDateForward() {
    let userDefaults = UserDefaults(suiteName: suiteName)!
    let provider = AdjustableDateProvider(userDefaults: userDefaults)
    provider.dayOffset = 3

    let now = Date()
    let interval = provider.now.timeIntervalSince(now)
    let expectedInterval = 3 * 86_400.0

    XCTAssertEqual(interval, expectedInterval, accuracy: 5)
  }

  func testTimeTravelNegativeOffsetMovesDateBackward() {
    let userDefaults = UserDefaults(suiteName: suiteName)!
    let provider = AdjustableDateProvider(userDefaults: userDefaults)
    provider.dayOffset = -2

    let now = Date()
    let interval = provider.now.timeIntervalSince(now)
    let expectedInterval = -2 * 86_400.0

    XCTAssertEqual(interval, expectedInterval, accuracy: 5)
  }

  func testTimeTravelLabelForZero() {
    XCTAssertEqual(TimeTravel.label(for: 0), "today")
  }

  func testTimeTravelLabelForPositiveValue() {
    XCTAssertEqual(TimeTravel.label(for: 1), "+1 day")
    XCTAssertEqual(TimeTravel.label(for: 3), "+3 days")
  }

  func testTimeTravelLabelForNegativeValue() {
    XCTAssertEqual(TimeTravel.label(for: -1), "-1 day")
    XCTAssertEqual(TimeTravel.label(for: -2), "-2 days")
  }
}
