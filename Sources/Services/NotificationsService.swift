import Foundation
import UserNotifications

/// Seam over `UNUserNotificationCenter` so tests never touch the real notification center.
protocol UserNotificationCentering: AnyObject {
  func authorizationStatus() async -> UNAuthorizationStatus
  func requestAuthorization() async throws -> Bool
  func add(_ request: UNNotificationRequest) async throws
  func removePendingRequests(withIdentifiers ids: [String])
  func pendingRequests() async -> [UNNotificationRequest]
}

extension UNUserNotificationCenter: UserNotificationCentering {
  func authorizationStatus() async -> UNAuthorizationStatus {
    await notificationSettings().authorizationStatus
  }

  func requestAuthorization() async throws -> Bool {
    try await requestAuthorization(options: [.alert, .sound, .badge])
  }

  func removePendingRequests(withIdentifiers ids: [String]) {
    removePendingNotificationRequests(withIdentifiers: ids)
  }

  func pendingRequests() async -> [UNNotificationRequest] {
    await pendingNotificationRequests()
  }
}

/// Local-notification service that nudges only when reviews are actually due.
///
/// DECIDED: no `UNUserNotificationCenterDelegate` in v1 — a notification firing while the
/// app is foregrounded is intentionally not presented; the in-app ReviewsBanner already
/// covers the foreground case. Tap-to-open routing to the Reviews tab is a deliberate
/// deferral; if presentation is ever added, the delegate must be assigned in `EnoughApp`
/// init before launch finishes.
final class NotificationsService {
  static let reviewDueIdentifier = "review-due"

  let center: UserNotificationCentering

  init(center: UserNotificationCentering) {
    self.center = center
  }

  /// Reads the LIVE authorization status every call — never cached, since a cached grant
  /// goes stale the moment the user flips the switch in Settings, in either direction. The
  /// system itself guarantees the user is only ever prompted once; no app-side bookkeeping
  /// is needed or wanted.
  func requestPermissionIfNeeded() async -> Bool {
    switch await center.authorizationStatus() {
    case .authorized, .provisional, .ephemeral:
      return true
    case .denied:
      return false
    case .notDetermined:
      return (try? await center.requestAuthorization()) ?? false
    @unknown default:
      return false
    }
  }

  func rescheduleReviewNotification(dueCount: Int, nextDueDate: Date?) async {
    center.removePendingRequests(withIdentifiers: [Self.reviewDueIdentifier])

    guard let nextDueDate, dueCount > 0, nextDueDate > Date() else { return }

    let content = UNMutableNotificationContent()
    content.title = "Enough"
    content.body = dueCount == 1 ? "1 card is slipping" : "\(dueCount) cards are slipping"

    // Known, acceptable debug-only skew: under T039 time travel the forecast uses the
    // offset clock while the delivered trigger fires on wall-clock time.
    let components = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute, .second], from: nextDueDate
    )
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    let request = UNNotificationRequest(
      identifier: Self.reviewDueIdentifier, content: content, trigger: trigger
    )

    try? await center.add(request)
  }

  func cancelAll() {
    center.removePendingRequests(withIdentifiers: [Self.reviewDueIdentifier])
  }

  /// Pure helper: `fireAt` is the earliest due date strictly after `now` (nil if none);
  /// `count` is how many `dueDates` are at or before `fireAt` (already-due cards still
  /// count, since they'll still be due then too).
  static func forecast(dueDates: [Date], now: Date) -> (count: Int, fireAt: Date)? {
    guard let fireAt = dueDates.filter({ $0 > now }).min() else { return nil }
    let count = dueDates.filter { $0 <= fireAt }.count
    return (count, fireAt)
  }
}

/// No-op fake used by `AppServices.preview()` — never touches the real notification center.
final class NoopNotificationCenter: UserNotificationCentering {
  func authorizationStatus() async -> UNAuthorizationStatus { .notDetermined }
  func requestAuthorization() async throws -> Bool { false }
  func add(_ request: UNNotificationRequest) async throws {}
  func removePendingRequests(withIdentifiers ids: [String]) {}
  func pendingRequests() async -> [UNNotificationRequest] { [] }
}
