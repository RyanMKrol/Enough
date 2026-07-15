import Foundation
import SwiftData

final class EntitlementStore {
  private let context: ModelContext

  init(context: ModelContext) {
    self.context = context
  }

  func grant(productId: String, kind: String, now: Date) throws {
    let existing = try context.fetch(FetchDescriptor<EntitlementRecord>())
    if existing.contains(where: { $0.productId == productId }) {
      return
    }
    let record = EntitlementRecord(productId: productId, kind: kind, grantedAt: now)
    context.insert(record)
    try context.save()
  }

  func grantedProductIds() throws -> Set<String> {
    let records = try context.fetch(FetchDescriptor<EntitlementRecord>())
    return Set(records.map(\.productId))
  }

  func ownedDeckIds(catalog: ContentCatalog) throws -> Set<String> {
    let granted = try grantedProductIds()
    var owned = Set<String>()

    for country in catalog.countries {
      for bundle in country.bundles where granted.contains(bundle.id) {
        owned.formUnion(bundle.deckIds)
      }
      for deck in country.decks where granted.contains(deck.id) {
        owned.insert(deck.id)
      }
    }

    return owned
  }

  func isOwned(deckId: String, catalog: ContentCatalog) throws -> Bool {
    try ownedDeckIds(catalog: catalog).contains(deckId)
  }

  func revoke(productId: String) throws {
    let records = try context.fetch(FetchDescriptor<EntitlementRecord>())
    for record in records where record.productId == productId {
      context.delete(record)
    }
    try context.save()
  }

  func reset() throws {
    let records = try context.fetch(FetchDescriptor<EntitlementRecord>())
    for record in records {
      context.delete(record)
    }
    try context.save()
  }
}
