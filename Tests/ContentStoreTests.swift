import XCTest
@testable import Enough

@MainActor
final class ContentStoreTests: XCTestCase {
  var store: ContentStore!

  override func setUp() {
    super.setUp()
    store = ContentStore()
  }

  func testCatalogBasics() throws {
    let catalog = try store.catalog()
    XCTAssertEqual(catalog.version, 1)
    XCTAssertEqual(catalog.countries.count, 3)
    XCTAssertEqual(catalog.countries.map { $0.id }, ["japan", "france", "germany"])
    XCTAssertEqual(catalog.scenarios.count, 6)
    XCTAssertEqual(catalog.comingSoon, ["Italy", "Spain", "Thailand"])
  }

  func testJapanCountry() throws {
    let japan = try store.country("japan")
    XCTAssertEqual(japan.decks.count, 4)
    XCTAssertEqual(japan.bundles.count, 2)
    XCTAssertEqual(japan.decks.first?.id, "jp-greetings")
    let greetingsDeck = try XCTUnwrap(japan.decks.first)
    XCTAssertEqual(greetingsDeck.cardCount, 30)
    XCTAssertEqual(greetingsDeck.priceGBP, 1.0)

    let weekendBundle = try XCTUnwrap(japan.bundles.first)
    XCTAssertEqual(weekendBundle.id, "jp-weekend")
    XCTAssertEqual(weekendBundle.priceGBP, 2.49)
    XCTAssertTrue(weekendBundle.popular)
    XCTAssertEqual(weekendBundle.deckIds.count, 3)
  }

  func testJapanGreetingsCards() throws {
    let cards = try store.cards(forDeck: "jp-greetings")
    XCTAssertEqual(cards.count, 30)

    let firstCard = try XCTUnwrap(cards.first)
    XCTAssertEqual(firstCard.id, "ohayou-gozaimasu")
    XCTAssertFalse(firstCard.english.isEmpty)
    XCTAssertFalse(firstCard.target.isEmpty)
    XCTAssertFalse(firstCard.pronunciation.isEmpty)
    XCTAssertFalse(firstCard.audio.isEmpty)
  }

  func testAudioURL() throws {
    let cards = try store.cards(forDeck: "jp-greetings")
    let firstCard = try XCTUnwrap(cards.first)
    let audioURL = store.audioURL(forFile: firstCard.audio)
    XCTAssertNotNil(audioURL)
    XCTAssertTrue(audioURL?.path.hasSuffix(firstCard.audio) ?? false)

    let missingAudioURL = store.audioURL(forFile: "nope.mp3")
    XCTAssertNil(missingAudioURL)
  }

  func testDeckLookup() throws {
    let deck = try store.deck("jp-at-the-bar")
    XCTAssertEqual(deck.title, "At the bar")
  }

  func testDeckNotFound() throws {
    XCTAssertThrowsError(try store.deck("bogus")) { error in
      if case ContentStoreError.deckNotFound = error {
        // Expected
      } else {
        XCTFail("Expected deckNotFound error")
      }
    }
  }

  func testCountryNotFound() throws {
    XCTAssertThrowsError(try store.country("bogus")) { error in
      if case ContentStoreError.countryNotFound = error {
        // Expected
      } else {
        XCTFail("Expected countryNotFound error")
      }
    }
  }

  func testCatalogCaching() throws {
    let first = try store.catalog()
    let second = try store.catalog()
    XCTAssertEqual(first, second)
  }
}
