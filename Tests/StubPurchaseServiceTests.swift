import SwiftData
import XCTest

@testable import Enough

@MainActor
final class StubPurchaseServiceTests: XCTestCase {
  private func makeService(
    catalog: ContentCatalog?
  ) throws -> (StubPurchaseService, ModelContext) {
    let container = try PersistenceStack.container(inMemory: true)
    let context = ModelContext(container)
    let store = EntitlementStore(context: context)
    let service = StubPurchaseService(entitlements: store, catalog: catalog)
    return (service, context)
  }

  func testPurchaseSingleDeck() async throws {
    let store = ContentStore()
    let catalog = try store.catalog()
    let (service, context) = try makeService(catalog: catalog)
    let entitlements = EntitlementStore(context: context)

    var notificationCount = 0
    let token = NotificationCenter.default.addObserver(
      forName: .entitlementsChanged,
      object: nil,
      queue: .main
    ) { _ in notificationCount += 1 }
    defer { NotificationCenter.default.removeObserver(token) }

    let outcome = try await service.purchase(productId: "jp-greetings", kind: .deck)

    XCTAssertEqual(outcome, .success)
    XCTAssertTrue(service.ownedProductIds.contains("jp-greetings"))
    XCTAssertEqual(notificationCount, 1)
    XCTAssertTrue(try entitlements.isOwned(deckId: "jp-greetings", catalog: catalog))
  }

  func testPurchaseSameDeckTwiceIsIdempotent() async throws {
    let store = ContentStore()
    let catalog = try store.catalog()
    let (service, context) = try makeService(catalog: catalog)

    _ = try await service.purchase(productId: "jp-greetings", kind: .deck)
    _ = try await service.purchase(productId: "jp-greetings", kind: .deck)

    let records = try context.fetch(FetchDescriptor<EntitlementRecord>())
    let greetingsRecords = records.filter { $0.productId == "jp-greetings" }
    XCTAssertEqual(greetingsRecords.count, 1)
  }

  func testPurchaseBundle() async throws {
    let store = ContentStore()
    let catalog = try store.catalog()
    let (service, context) = try makeService(catalog: catalog)
    let entitlements = EntitlementStore(context: context)

    _ = try await service.purchase(productId: "jp-greetings", kind: .deck)
    _ = try await service.purchase(productId: "jp-weekend", kind: .bundle)

    XCTAssertTrue(service.ownedProductIds.contains("jp-weekend"))
    let ownedDeckIds = try entitlements.ownedDeckIds(catalog: catalog)
    XCTAssertTrue(ownedDeckIds.contains("jp-greetings"))
    XCTAssertTrue(ownedDeckIds.contains("jp-ordering-food"))
    XCTAssertTrue(ownedDeckIds.contains("jp-at-the-bar"))
    XCTAssertFalse(ownedDeckIds.contains("jp-getting-around"))
  }

  func testRestorePostsNotification() async throws {
    let store = ContentStore()
    let catalog = try store.catalog()
    let (service, _) = try makeService(catalog: catalog)

    _ = try await service.purchase(productId: "jp-greetings", kind: .deck)

    var notificationCount = 0
    let token = NotificationCenter.default.addObserver(
      forName: .entitlementsChanged,
      object: nil,
      queue: .main
    ) { _ in notificationCount += 1 }
    defer { NotificationCenter.default.removeObserver(token) }

    try await service.restorePurchases()

    XCTAssertEqual(notificationCount, 1)
    XCTAssertTrue(service.ownedProductIds.contains("jp-greetings"))
  }

  func testDisplayPrice() async throws {
    let store = ContentStore()
    let catalog = try store.catalog()
    let (service, _) = try makeService(catalog: catalog)

    XCTAssertEqual(service.displayPrice(productId: "jp-greetings"), "£1.00")
    XCTAssertEqual(service.displayPrice(productId: "jp-weekend"), "£2.49")
    XCTAssertNil(service.displayPrice(productId: "unknown-id"))
  }

  func testDisplayPriceWithNoCatalog() async throws {
    let (service, _) = try makeService(catalog: nil)

    XCTAssertNil(service.displayPrice(productId: "jp-greetings"))
  }
}
