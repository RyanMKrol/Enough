import Foundation
import SwiftData

enum DebugEntitlementTools {
  /// Grants every deck (kind .deck) and bundle (kind .bundle) of every country in the
  /// catalog via EntitlementStore.grant(productId:kind:now:). Idempotent (granting an
  /// already-owned product must not duplicate or throw). Returns the number of DECKS owned
  /// after the sweep.
  static func grantAll(
    catalog: ContentCatalog, entitlements: EntitlementStore, now: Date
  ) throws -> Int {
    for country in catalog.countries {
      for deck in country.decks {
        try entitlements.grant(productId: deck.id, kind: "deck", now: now)
      }
      for bundle in country.bundles {
        try entitlements.grant(productId: bundle.id, kind: "bundle", now: now)
      }
    }

    let allDeckIds = catalog.countries.flatMap(\.decks).map(\.id)
    return allDeckIds.count
  }
}
