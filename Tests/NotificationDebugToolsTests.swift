import UserNotifications
import XCTest

@testable import Enough

@MainActor
final class NotificationDebugToolsTests: XCTestCase {
  private final class SpyNotificationCenter: UserNotificationCentering {
    var addedRequests: [UNNotificationRequest] = []

    func authorizationStatus() async -> UNAuthorizationStatus { .authorized }

    func requestAuthorization() async throws -> Bool { true }

    func add(_ request: UNNotificationRequest) async throws {
      addedRequests.append(request)
    }

    func removePendingRequests(withIdentifiers ids: [String]) {}

    func pendingRequests() async -> [UNNotificationRequest] { addedRequests }
  }

  func testFireTestNotificationSchedulesWithTwoSecondTrigger() async throws {
    let spy = SpyNotificationCenter()
    let service = NotificationsService(center: spy)

    let body = try await service.fireTestNotification(dueCount: 12)

    XCTAssertEqual(body, "12 cards are slipping")
    XCTAssertEqual(spy.addedRequests.count, 1)

    let request = try XCTUnwrap(spy.addedRequests.first)
    XCTAssertEqual(request.identifier, "debug.test-review-notification")
    XCTAssertEqual(request.content.body, "12 cards are slipping")

    let trigger = try XCTUnwrap(request.trigger as? UNTimeIntervalNotificationTrigger)
    XCTAssertEqual(trigger.timeInterval, 2)
    XCTAssertFalse(trigger.repeats)
  }

  func testFireTestNotificationWithSingleCardUsesCorrectBody() async throws {
    let spy = SpyNotificationCenter()
    let service = NotificationsService(center: spy)

    let body = try await service.fireTestNotification(dueCount: 1)

    XCTAssertEqual(body, "1 card is slipping")

    let request = try XCTUnwrap(spy.addedRequests.first)
    XCTAssertEqual(request.content.body, "1 card is slipping")
  }

  func testPendingSummaryReportsNoPendingWhenEmpty() async {
    let spy = SpyNotificationCenter()
    let service = NotificationsService(center: spy)

    let summary = await service.pendingSummary()

    XCTAssertEqual(summary, "none pending")
  }

  func testPendingSummaryReportsCountAndTime() async throws {
    let spy = SpyNotificationCenter()
    let service = NotificationsService(center: spy)

    _ = try await service.fireTestNotification(dueCount: 12)

    let summary = await service.pendingSummary()

    XCTAssertTrue(summary.contains("1 pending"))
    XCTAssertTrue(summary.contains("in ~2s"))
  }
}
