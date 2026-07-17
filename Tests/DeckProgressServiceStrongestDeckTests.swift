import SwiftData
import XCTest

@testable import Enough

@MainActor
final class DeckProgressServiceStrongestDeckTests: XCTestCase {
  private struct FixedDateProvider: DateProvider {
    let now: Date
  }

  private func makeContext() throws -> ModelContext {
    let container = try PersistenceStack.container(inMemory: true)
    return ModelContext(container)
  }

  private struct SeedSpec {
    let deckId: String
    let cardIds: [String]
    let statusRaw: String
    let intervalDays: Double
    let dueAt: Date?
  }

  private func seedRecords(_ store: CardSRSStore, _ spec: SeedSpec) throws {
    for cardId in spec.cardIds {
      try store.upsert(
        deckId: spec.deckId, cardId: cardId, statusRaw: spec.statusRaw, easeFactor: 2.5,
        intervalDays: spec.intervalDays, repetitions: 1, lapses: 0, dueAt: spec.dueAt,
        lastReviewedAt: nil
      )
    }
  }

  func testStrongestDeckIdPicksHighestStrengthThenMostLearned() throws {
    let context = try makeContext()
    let srsStore = CardSRSStore(context: context)
    let entitlements = EntitlementStore(context: context)
    let content = ContentStore()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let oneHour: TimeInterval = 3600

    let weakCardIds = try content.cards(forDeck: "jp-greetings").map(\.id)
    // 1 learned, 1 due -> strength 1
    try seedRecords(
      srsStore,
      SeedSpec(
        deckId: "jp-greetings", cardIds: Array(weakCardIds[0..<1]), statusRaw: "review",
        intervalDays: 8, dueAt: now.addingTimeInterval(-oneHour)
      )
    )

    let strongCardIds = try content.cards(forDeck: "jp-at-the-bar").map(\.id)
    // learned, none due -> strength 3
    try seedRecords(
      srsStore,
      SeedSpec(
        deckId: "jp-at-the-bar", cardIds: Array(strongCardIds[0..<5]), statusRaw: "review",
        intervalDays: 30, dueAt: now.addingTimeInterval(oneHour)
      )
    )

    let service = DeckProgressService(
      content: content, srsStore: srsStore, entitlements: entitlements,
      dateProvider: FixedDateProvider(now: now)
    )

    let strongest = service.strongestDeckId(among: ["jp-greetings", "jp-at-the-bar"])
    XCTAssertEqual(strongest, "jp-at-the-bar")
  }

  func testStrongestDeckIdSkipsUnreadableDecksAndReturnsNilWhenNoneMatch() throws {
    let context = try makeContext()
    let srsStore = CardSRSStore(context: context)
    let entitlements = EntitlementStore(context: context)
    let content = ContentStore()
    let now = Date(timeIntervalSince1970: 1_700_000_000)

    let service = DeckProgressService(
      content: content, srsStore: srsStore, entitlements: entitlements,
      dateProvider: FixedDateProvider(now: now)
    )

    XCTAssertNil(service.strongestDeckId(among: ["bogus-deck"]))
  }
}
