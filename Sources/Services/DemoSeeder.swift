import Foundation
import SwiftData

/// Wipes all persisted data and writes a deterministic mid-trip fixture (day 2 of a
/// Tokyo weekend, 12 reviews due, 6-day streak) matching the design mocks.
enum DemoSeeder {
  private static let oneDay: TimeInterval = 86_400

  static func seed(content: ContentStore, context: ModelContext, now: Date) throws {
    try AppReset.wipeAll(context: context)

    let tripStore = TripStore(context: context)
    let entitlementStore = EntitlementStore(context: context)
    let srsStore = CardSRSStore(context: context)
    let activityStore = ActivityStore(context: context)

    try tripStore.saveNewTrip(
      countryId: "japan",
      duration: "weekend",
      scenarioIds: ["eating-out", "getting-around", "greetings"],
      accentRawValue: "japan",
      startDate: now.addingTimeInterval(-oneDay)
    )

    try entitlementStore.grant(productId: "jp-weekend", kind: "bundle", now: now)

    try seedGreetings(content: content, srsStore: srsStore, now: now)
    try seedOrderingFood(content: content, srsStore: srsStore, now: now)

    for dayOffset in 1...6 {
      let day = now.addingTimeInterval(-Double(dayOffset) * oneDay)
      try activityStore.addActivity(cardsReviewed: 12, cardsLearned: 6, seconds: 620, now: day)
    }
  }

  private static func seedGreetings(
    content: ContentStore, srsStore: CardSRSStore, now: Date
  ) throws {
    let lastReviewedAt = now.addingTimeInterval(-oneDay)
    let cardIds = try content.cards(forDeck: "jp-greetings").map(\.id)

    for cardId in cardIds.prefix(5) {
      try srsStore.upsert(
        deckId: "jp-greetings", cardId: cardId, statusRaw: "review",
        easeFactor: 2.5, intervalDays: 30, repetitions: 4, lapses: 0,
        dueAt: now.addingTimeInterval(20 * oneDay), lastReviewedAt: lastReviewedAt
      )
    }
    for cardId in cardIds.dropFirst(5).prefix(18) {
      try srsStore.upsert(
        deckId: "jp-greetings", cardId: cardId, statusRaw: "review",
        easeFactor: 2.5, intervalDays: 7, repetitions: 3, lapses: 0,
        dueAt: now.addingTimeInterval(4 * oneDay), lastReviewedAt: lastReviewedAt
      )
    }
    for cardId in cardIds.dropFirst(23).prefix(7) {
      try srsStore.upsert(
        deckId: "jp-greetings", cardId: cardId, statusRaw: "review",
        easeFactor: 2.5, intervalDays: 3, repetitions: 2, lapses: 0,
        dueAt: now.addingTimeInterval(-3_600), lastReviewedAt: lastReviewedAt
      )
    }
  }

  private static func seedOrderingFood(
    content: ContentStore, srsStore: CardSRSStore, now: Date
  ) throws {
    let lastReviewedAt = now.addingTimeInterval(-oneDay)
    let cardIds = try content.cards(forDeck: "jp-ordering-food").map(\.id)

    for cardId in cardIds.prefix(5) {
      try srsStore.upsert(
        deckId: "jp-ordering-food", cardId: cardId, statusRaw: "learning",
        easeFactor: 2.5, intervalDays: 1, repetitions: 1, lapses: 0,
        dueAt: now.addingTimeInterval(-3_600), lastReviewedAt: lastReviewedAt
      )
    }
    for cardId in cardIds.dropFirst(5).prefix(3) {
      try srsStore.upsert(
        deckId: "jp-ordering-food", cardId: cardId, statusRaw: "learning",
        easeFactor: 2.5, intervalDays: 1, repetitions: 1, lapses: 0,
        dueAt: now.addingTimeInterval(oneDay), lastReviewedAt: lastReviewedAt
      )
    }
  }
}
