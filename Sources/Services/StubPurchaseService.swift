import Foundation
import SwiftData

final class StubPurchaseService: PurchaseProviding {
  private let entitlements: EntitlementStore
  private let catalog: ContentCatalog?

  init(entitlements: EntitlementStore, catalog: ContentCatalog?) {
    self.entitlements = entitlements
    self.catalog = catalog
  }

  var ownedProductIds: Set<String> {
    do {
      return try entitlements.grantedProductIds()
    } catch {
      return []
    }
  }

  func purchase(productId: String, kind: EntitlementKind) async throws -> PurchaseOutcome {
    try? await Task.sleep(nanoseconds: 300_000_000)
    try entitlements.grant(productId: productId, kind: kind.rawValue, now: Date())
    await NotificationCenter.default.post(name: .entitlementsChanged, object: nil)
    return .success
  }

  func restorePurchases() async throws {
    await NotificationCenter.default.post(name: .entitlementsChanged, object: nil)
  }

  func displayPrice(productId: String) -> String? {
    guard let catalog = catalog else { return nil }
    for country in catalog.countries {
      if let deck = country.decks.first(where: { $0.id == productId }) {
        return PricingCalculator.price(deck.priceGBP)
      }
      if let bundle = country.bundles.first(where: { $0.id == productId }) {
        return PricingCalculator.price(bundle.priceGBP)
      }
    }
    return nil
  }
}
