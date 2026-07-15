import XCTest

@testable import Enough

final class ContentModelsTests: XCTestCase {
  func testContentCatalogDecodes() throws {
    let json = """
      {
        "version": 1,
        "scenarios": [
          {"id": "restaurant", "title": "Restaurant"},
          {"id": "airport", "title": "Airport"}
        ],
        "countries": [
          {
            "id": "japan",
            "name": "Japan",
            "languageName": "Japanese",
            "nativeLanguageName": "日本語",
            "accent": "Tokyo",
            "flagEmoji": "🇯🇵",
            "decks": [
              {
                "id": "jp-restaurant",
                "title": "Restaurant",
                "subtitle": "Order with confidence",
                "scenario": "restaurant",
                "icon": "fork.knife",
                "cardsFile": "jp-restaurant.json",
                "cardCount": 20,
                "priceGBP": 1.0
              }
            ],
            "bundles": [
              {
                "id": "jp-weekend",
                "title": "Weekend",
                "subtitle": "Just enough",
                "deckIds": ["jp-restaurant"],
                "priceGBP": 5.0,
                "popular": true
              }
            ]
          }
        ],
        "comingSoon": ["italy"]
      }
      """
    let data = Data(json.utf8)
    let catalog = try JSONDecoder().decode(ContentCatalog.self, from: data)
    try assertDecodedCatalog(catalog)
  }

  private func assertDecodedCatalog(_ catalog: ContentCatalog) throws {
    XCTAssertEqual(catalog.version, 1)
    XCTAssertEqual(catalog.scenarios.map(\.id), ["restaurant", "airport"])
    XCTAssertEqual(catalog.countries.first?.id, "japan")
    XCTAssertEqual(catalog.comingSoon, ["italy"])

    let deck = try XCTUnwrap(catalog.countries.first?.decks.first)
    XCTAssertEqual(deck.id, "jp-restaurant")
    XCTAssertEqual(deck.priceGBP, 1.0)

    let bundle = try XCTUnwrap(catalog.countries.first?.bundles.first)
    XCTAssertEqual(bundle.id, "jp-weekend")
    XCTAssertEqual(bundle.deckIds, ["jp-restaurant"])
    XCTAssertTrue(bundle.popular)
  }

  func testDeckCardsDecodesOptionalKeys() throws {
    let json = """
      {
        "deckId": "jp-restaurant",
        "cards": [
          {
            "id": "card-1",
            "english": "Hello",
            "target": "こんにちは",
            "pronunciation": "konnichiwa",
            "audio": "card-1.mp3",
            "notes": "Used any time of day",
            "category": "greetings"
          },
          {
            "id": "card-2",
            "english": "Goodbye",
            "target": "さようなら",
            "pronunciation": "sayounara",
            "audio": "card-2.mp3"
          }
        ]
      }
      """
    let data = Data(json.utf8)
    let deckCards = try JSONDecoder().decode(DeckCards.self, from: data)

    XCTAssertEqual(deckCards.cards.count, 2)

    let card1 = deckCards.cards[0]
    XCTAssertEqual(card1.notes, "Used any time of day")
    XCTAssertEqual(card1.category, "greetings")

    let card2 = deckCards.cards[1]
    XCTAssertNil(card2.notes)
    XCTAssertNil(card2.category)
  }

  func testUnicodeSurvivesDecoding() throws {
    let json = """
      {
        "id": "card-3",
        "english": "Good morning",
        "target": "おはようございます。",
        "pronunciation": "ohayou gozaimasu",
        "audio": "card-3.mp3",
        "notes": null,
        "category": null
      }
      """
    let data = Data(json.utf8)
    let card = try JSONDecoder().decode(CardContent.self, from: data)

    XCTAssertEqual(card.target, "おはようございます。")
  }
}
