import Foundation

enum DebugNotifications {
  private static var cachedPendingSummary = "tap Fire to refresh"

  static let section = DebugSection(
    id: "notifications",
    title: "Notifications",
    rows: [
      DebugRow(
        id: "fire-test",
        title: "Fire review notification in 2s",
        subtitle: "Background the app to see the banner",
        kind: .action { services in
          do {
            let dueCount = try services.deckProgress.totalDue()
            let body = try await services.notifications.fireTestNotification(dueCount: dueCount)
            cachedPendingSummary = try await services.notifications.pendingSummary()
            return "Scheduled: \(body)"
          } catch {
            throw error
          }
        }
      ),
      DebugRow(
        id: "pending",
        title: "Pending notifications",
        kind: .info { _ in
          cachedPendingSummary
        }
      ),  // swiftlint:disable:this trailing_comma
    ]
  )
}
