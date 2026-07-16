import Foundation
import UserNotifications

/// Debug seam for NotificationsService — methods for firing test notifications and inspecting pending.
extension NotificationsService {
  /// Schedules the normal review-due notification with a 2-second UNTimeIntervalNotificationTrigger,
  /// identifier "debug.test-review-notification". Returns the body text it scheduled.
  func fireTestNotification(dueCount: Int) async throws -> String {
    let content = UNMutableNotificationContent()
    content.title = "Enough"
    content.body = dueCount == 1 ? "1 card is slipping" : "\(dueCount) cards are slipping"

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
    let request = UNNotificationRequest(
      identifier: "debug.test-review-notification", content: content, trigger: trigger
    )

    try await center.add(request)
    return content.body
  }

  /// "2 pending · next ~in 4h" style one-liner from getPendingNotificationRequests.
  /// Returns "none pending" when empty.
  func pendingSummary() async -> String {
    let requests = await center.pendingRequests()
    guard !requests.isEmpty else { return "none pending" }

    let count = requests.count
    let firstRequest = requests.first

    guard let firstRequest else { return "\(count) pending · no trigger" }

    let timeInterval = (firstRequest.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval
    let calendarTrigger = firstRequest.trigger as? UNCalendarNotificationTrigger

    let timeDescription: String
    if let timeInterval, timeInterval > 0 {
      if timeInterval < 60 {
        timeDescription = "in ~\(Int(timeInterval))s"
      } else if timeInterval < 3600 {
        let minutes = Int(timeInterval / 60)
        timeDescription = "in ~\(minutes)m"
      } else {
        let hours = Int(timeInterval / 3600)
        timeDescription = "in ~\(hours)h"
      }
    } else if let calendarTrigger {
      let now = Date()
      let nextFire = Calendar.current.nextDate(
        after: now, matching: calendarTrigger.dateComponents, matchingPolicy: .nextTime
      )
      if let nextFire {
        let interval = nextFire.timeIntervalSince(now)
        if interval < 60 {
          timeDescription = "in ~\(Int(interval))s"
        } else if interval < 3600 {
          let minutes = Int(interval / 60)
          timeDescription = "in ~\(minutes)m"
        } else {
          let hours = Int(interval / 3600)
          timeDescription = "in ~\(hours)h"
        }
      } else {
        timeDescription = "unknown"
      }
    } else {
      timeDescription = "unknown"
    }

    return "\(count) pending · next \(timeDescription)"
  }

}
