import SwiftData
import XCTest

@testable import Enough

@MainActor
class DebugEntitlementToolsTests: XCTestCase {
  func testGrantAllGrantsAllDecksAndBundlesAndIsIdempotent() throws {
    let container = try PersistenceStack.container(inMemory: true)
    let context = ModelContext(container)
    let contentStore = ContentStore()
    let entitlementStore = EntitlementStore(context: context)
    let catalog = try contentStore.catalog()
    let now = Date()

    let firstCount = try DebugEntitlementTools.grantAll(
      catalog: catalog, entitlements: entitlementStore, now: now)
    let secondCount = try DebugEntitlementTools.grantAll(
      catalog: catalog, entitlements: entitlementStore, now: now)

    let allDeckIds = Set(catalog.countries.flatMap(\.decks).map(\.id))
    let ownedDeckIds = try entitlementStore.ownedDeckIds(catalog: catalog)

    XCTAssertEqual(firstCount, allDeckIds.count)
    XCTAssertEqual(secondCount, allDeckIds.count)
    XCTAssertEqual(ownedDeckIds, allDeckIds)
  }
}
