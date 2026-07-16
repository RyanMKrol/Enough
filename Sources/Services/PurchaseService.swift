import Foundation

enum EntitlementKind: String, Sendable {
  case deck
  case bundle
}

enum PurchaseOutcome {
  case success
  case cancelled
  case pending
}

protocol PurchaseProviding: AnyObject {
  var ownedProductIds: Set<String> { get }
  func purchase(productId: String, kind: EntitlementKind) async throws -> PurchaseOutcome
  func restorePurchases() async throws
  func displayPrice(productId: String) -> String?
}

extension Notification.Name {
  /// Posted (on the main actor) whenever the owned-entitlements set may have changed.
  static let entitlementsChanged = Notification.Name("enough.entitlements.changed")
}
