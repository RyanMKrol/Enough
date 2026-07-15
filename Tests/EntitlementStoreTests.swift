import SwiftData
import XCTest

@testable import Enough

@MainActor
class EntitlementStoreTests: XCTestCase {
  private func makeStore() throws -> (EntitlementStore, ModelContext) {
    let container = try PersistenceStack.container(inMemory: true)
    let context = ModelContext(container)
    return (EntitlementStore(context: context), context)
  }

  private func makeCatalog() -> ContentCatalog {
    let deck1 = DeckInfo(
      id: "d1", title: "D1", subtitle: "", scenario: "s", icon: "icon",
      cardsFile: "d1.json", cardCount: 1, priceGBP: 1)
    let deck2 = DeckInfo(
      id: "d2", title: "D2", subtitle: "", scenario: "s", icon: "icon",
      cardsFile: "d2.json", cardCount: 1, priceGBP: 1)
    let deck3 = DeckInfo(
      id: "d3", title: "D3", subtitle: "", scenario: "s", icon: "icon",
      cardsFile: "d3.json", cardCount: 1, priceGBP: 1)
    let bundle = BundleInfo(
      id: "b1", title: "Bundle", subtitle: "", deckIds: ["d1", "d2"], priceGBP: 2, popular: false)
    let country = CountryInfo(
      id: "country", name: "Country", languageName: "Lang", nativeLanguageName: "Lang",
      accent: "accent", flagEmoji: "🏳️", decks: [deck1, deck2, deck3], bundles: [bundle])
    return ContentCatalog(version: 1, scenarios: [], countries: [country], comingSoon: [])
  }

  func testEmptyStore() throws {
    let (store, _) = try makeStore()
    let catalog = makeCatalog()
    XCTAssertTrue(try store.grantedProductIds().isEmpty)
    XCTAssertTrue(try store.ownedDeckIds(catalog: catalog).isEmpty)
    XCTAssertFalse(try store.isOwned(deckId: "d1", catalog: catalog))
  }

  func testGrantDeck() throws {
    let (store, _) = try makeStore()
    let catalog = makeCatalog()

    try store.grant(productId: "d3", kind: "deck", now: Date(timeIntervalSince1970: 0))

    XCTAssertEqual(try store.ownedDeckIds(catalog: catalog), ["d3"])
    XCTAssertTrue(try store.isOwned(deckId: "d3", catalog: catalog))
    XCTAssertFalse(try store.isOwned(deckId: "d1", catalog: catalog))
  }

  func testGrantBundleExpandsToMemberDecks() throws {
    let (store, _) = try makeStore()
    let catalog = makeCatalog()

    try store.grant(productId: "d3", kind: "deck", now: Date(timeIntervalSince1970: 0))
    try store.grant(productId: "b1", kind: "bundle", now: Date(timeIntervalSince1970: 0))

    XCTAssertEqual(try store.ownedDeckIds(catalog: catalog), ["d1", "d2", "d3"])
  }

  func testGrantIsIdempotent() throws {
    let (store, context) = try makeStore()

    try store.grant(productId: "b1", kind: "bundle", now: Date(timeIntervalSince1970: 0))
    try store.grant(productId: "b1", kind: "bundle", now: Date(timeIntervalSince1970: 0))

    let records = try context.fetch(FetchDescriptor<EntitlementRecord>())
    XCTAssertEqual(records.count, 1)
  }

  func testGhostGrantIsIgnored() throws {
    let (store, _) = try makeStore()
    let catalog = makeCatalog()

    try store.grant(productId: "ghost", kind: "deck", now: Date(timeIntervalSince1970: 0))

    XCTAssertTrue(try store.ownedDeckIds(catalog: catalog).isEmpty)
  }

  func testRevoke() throws {
    let (store, _) = try makeStore()
    let catalog = makeCatalog()

    try store.grant(productId: "d3", kind: "deck", now: Date(timeIntervalSince1970: 0))
    try store.revoke(productId: "d3")

    XCTAssertFalse(try store.ownedDeckIds(catalog: catalog).contains("d3"))

    try store.revoke(productId: "never-granted")
    XCTAssertTrue(try store.ownedDeckIds(catalog: catalog).isEmpty)
  }

  func testReset() throws {
    let (store, _) = try makeStore()

    try store.grant(productId: "d3", kind: "deck", now: Date(timeIntervalSince1970: 0))
    try store.reset()

    XCTAssertTrue(try store.grantedProductIds().isEmpty)
  }
}
