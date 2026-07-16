import UserNotifications
import XCTest

@testable import Enough

@MainActor
final class NotificationsServiceTests: XCTestCase {
  private final class FakeNotificationCenter: UserNotificationCentering {
    var status: UNAuthorizationStatus = .notDetermined
    var requestAuthorizationResult = true
    var requestAuthorizationCallCount = 0
    var addedRequests: [UNNotificationRequest] = []
    var removedIdentifiers: [[String]] = []

    func authorizationStatus() async -> UNAuthorizationStatus { status }

    func requestAuthorization() async throws -> Bool {
      requestAuthorizationCallCount += 1
      return requestAuthorizationResult
    }

    func add(_ request: UNNotificationRequest) async throws {
      addedRequests.append(request)
    }

    func removePendingRequests(withIdentifiers ids: [String]) {
      removedIdentifiers.append(ids)
    }

    func pendingRequests() async -> [UNNotificationRequest] { addedRequests }
  }

  private let defaultsSuiteName = "NotificationsServiceTests"

  override func tearDown() {
    UserDefaults().removePersistentDomain(forName: defaultsSuiteName)
    super.tearDown()
  }

  func testRequestPermissionWhenNotDeterminedRequestsAuthorization() async {
    let center = FakeNotificationCenter()
    center.status = .notDetermined
    center.requestAuthorizationResult = true
    let service = NotificationsService(center: center)

    let granted = await service.requestPermissionIfNeeded()

    XCTAssertTrue(granted)
    XCTAssertEqual(center.requestAuthorizationCallCount, 1)
  }

  func testRequestPermissionWhenDeniedReturnsFalseWithoutRequesting() async {
    let center = FakeNotificationCenter()
    center.status = .denied
    let service = NotificationsService(center: center)

    let granted = await service.requestPermissionIfNeeded()

    XCTAssertFalse(granted)
    XCTAssertEqual(center.requestAuthorizationCallCount, 0)
  }

  func testRequestPermissionWhenAuthorizedReturnsTrueWithoutRequesting() async {
    let center = FakeNotificationCenter()
    center.status = .authorized
    let service = NotificationsService(center: center)

    let granted = await service.requestPermissionIfNeeded()

    XCTAssertTrue(granted)
    XCTAssertEqual(center.requestAuthorizationCallCount, 0)

    // The fake notification center is the only state consulted — nothing written to
    // UserDefaults.
    let persistedDomain = UserDefaults().persistentDomain(forName: defaultsSuiteName)
    XCTAssertNil(persistedDomain)
  }

  func testRescheduleWithDueCardsAddsSingleNonRepeatingRequest() async throws {
    let center = FakeNotificationCenter()
    let service = NotificationsService(center: center)
    var components = DateComponents()
    components.year = 2026
    components.month = 7
    components.day = 20
    components.hour = 9
    components.minute = 30
    components.second = 15
    let dueDate = try XCTUnwrap(Calendar.current.date(from: components))

    await service.rescheduleReviewNotification(dueCount: 12, nextDueDate: dueDate)

    XCTAssertEqual(center.removedIdentifiers, [["review-due"]])
    XCTAssertEqual(center.addedRequests.count, 1)
    let request = try XCTUnwrap(center.addedRequests.first)
    XCTAssertEqual(request.identifier, "review-due")
    XCTAssertEqual(request.content.body, "12 cards are slipping")

    let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
    XCTAssertFalse(trigger.repeats)
    XCTAssertEqual(trigger.dateComponents.year, 2026)
    XCTAssertEqual(trigger.dateComponents.month, 7)
    XCTAssertEqual(trigger.dateComponents.day, 20)
    XCTAssertEqual(trigger.dateComponents.hour, 9)
    XCTAssertEqual(trigger.dateComponents.minute, 30)
    XCTAssertEqual(trigger.dateComponents.second, 15)
  }

  func testRescheduleWithZeroDueCountOnlyRemoves() async {
    let center = FakeNotificationCenter()
    let service = NotificationsService(center: center)

    await service.rescheduleReviewNotification(
      dueCount: 0, nextDueDate: Date().addingTimeInterval(3600)
    )

    XCTAssertEqual(center.removedIdentifiers, [["review-due"]])
    XCTAssertTrue(center.addedRequests.isEmpty)
  }

  func testRescheduleWithPastDueDateOnlyRemoves() async {
    let center = FakeNotificationCenter()
    let service = NotificationsService(center: center)

    await service.rescheduleReviewNotification(
      dueCount: 5, nextDueDate: Date().addingTimeInterval(-3600)
    )

    XCTAssertEqual(center.removedIdentifiers, [["review-due"]])
    XCTAssertTrue(center.addedRequests.isEmpty)
  }

  func testRescheduleWithNilDueDateOnlyRemoves() async {
    let center = FakeNotificationCenter()
    let service = NotificationsService(center: center)

    await service.rescheduleReviewNotification(dueCount: 5, nextDueDate: nil)

    XCTAssertEqual(center.removedIdentifiers, [["review-due"]])
    XCTAssertTrue(center.addedRequests.isEmpty)
  }

  func testRescheduleWithSingleCardUsesSingularBody() async throws {
    let center = FakeNotificationCenter()
    let service = NotificationsService(center: center)

    await service.rescheduleReviewNotification(
      dueCount: 1, nextDueDate: Date().addingTimeInterval(3600)
    )

    let request = try XCTUnwrap(center.addedRequests.first)
    XCTAssertEqual(request.content.body, "1 card is slipping")
  }

  func testForecastReturnsEarliestFutureDateAndCountIncludingAlreadyDue() throws {
    let now = Date(timeIntervalSince1970: 1_000_000)
    let past = now.addingTimeInterval(-100)
    let soon = now.addingTimeInterval(100)
    let later = now.addingTimeInterval(200)

    let forecast = NotificationsService.forecast(dueDates: [past, soon, later], now: now)

    let result = try XCTUnwrap(forecast)
    XCTAssertEqual(result.fireAt, soon)
    XCTAssertEqual(result.count, 2)
  }

  func testForecastReturnsNilWhenNoFutureDates() {
    let now = Date(timeIntervalSince1970: 1_000_000)
    let past = now.addingTimeInterval(-100)

    let forecast = NotificationsService.forecast(dueDates: [past], now: now)

    XCTAssertNil(forecast)
  }
}
