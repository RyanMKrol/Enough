import Foundation
import SwiftData

final class CardSRSStore {
  private let context: ModelContext

  init(context: ModelContext) {
    self.context = context
  }

  func record(deckId: String, cardId: String) throws -> CardSRSRecord? {
    var descriptor = FetchDescriptor<CardSRSRecord>(
      predicate: #Predicate { $0.deckId == deckId && $0.cardId == cardId }
    )
    descriptor.fetchLimit = 1
    return try context.fetch(descriptor).first
  }

  @discardableResult
  // swiftlint:disable:next function_parameter_count
  func upsert(
    deckId: String, cardId: String, statusRaw: String, easeFactor: Double,
    intervalDays: Double, repetitions: Int, lapses: Int, dueAt: Date?,
    lastReviewedAt: Date?
  ) throws -> CardSRSRecord {
    if let existing = try record(deckId: deckId, cardId: cardId) {
      existing.statusRaw = statusRaw
      existing.easeFactor = easeFactor
      existing.intervalDays = intervalDays
      existing.repetitions = repetitions
      existing.lapses = lapses
      existing.dueAt = dueAt
      existing.lastReviewedAt = lastReviewedAt
      try context.save()
      return existing
    }

    let record = CardSRSRecord(
      deckId: deckId,
      cardId: cardId,
      statusRaw: statusRaw,
      easeFactor: easeFactor,
      intervalDays: intervalDays,
      repetitions: repetitions,
      lapses: lapses,
      dueAt: dueAt,
      lastReviewedAt: lastReviewedAt
    )
    context.insert(record)
    try context.save()
    return record
  }

  func records(forDeck deckId: String) throws -> [CardSRSRecord] {
    try context.fetch(FetchDescriptor<CardSRSRecord>(predicate: #Predicate { $0.deckId == deckId }))
  }

  /// Fetches records for multiple decks in a single query, filtering in memory (same
  /// `Set.contains`-in-`#Predicate` crash-risk workaround as `dueRecords`).
  func records(forDecks deckIds: Set<String>) throws -> [CardSRSRecord] {
    try context.fetch(FetchDescriptor<CardSRSRecord>()).filter { deckIds.contains($0.deckId) }
  }

  struct Update {
    let deckId: String
    let cardId: String
    let statusRaw: String
    let easeFactor: Double
    let intervalDays: Double
    let repetitions: Int
    let lapses: Int
    let dueAt: Date?
    let lastReviewedAt: Date?
  }

  /// Applies multiple upserts against a single batched fetch and a single `context.save()`,
  /// instead of one fetch + one save per update (avoids N+1 SwiftData round-trips when
  /// committing a whole session at once).
  func upsertBatch(_ updates: [Update]) throws {
    guard !updates.isEmpty else { return }

    let deckIds = Set(updates.map(\.deckId))
    let existing = try records(forDecks: deckIds)
    var byKey = Dictionary(uniqueKeysWithValues: existing.map { ("\($0.deckId)|\($0.cardId)", $0) })

    for update in updates {
      let key = "\(update.deckId)|\(update.cardId)"
      if let record = byKey[key] {
        record.statusRaw = update.statusRaw
        record.easeFactor = update.easeFactor
        record.intervalDays = update.intervalDays
        record.repetitions = update.repetitions
        record.lapses = update.lapses
        record.dueAt = update.dueAt
        record.lastReviewedAt = update.lastReviewedAt
      } else {
        let record = CardSRSRecord(
          deckId: update.deckId,
          cardId: update.cardId,
          statusRaw: update.statusRaw,
          easeFactor: update.easeFactor,
          intervalDays: update.intervalDays,
          repetitions: update.repetitions,
          lapses: update.lapses,
          dueAt: update.dueAt,
          lastReviewedAt: update.lastReviewedAt
        )
        context.insert(record)
        byKey[key] = record
      }
    }

    try context.save()
  }

  func deleteAll(forDeck deckId: String) throws {
    let records = try records(forDeck: deckId)
    for record in records {
      context.delete(record)
    }
    try context.save()
  }

  func dueRecords(now: Date, ownedDeckIds: Set<String>) throws -> [CardSRSRecord] {
    let sentinel = Date.distantFuture
    let predicate = #Predicate<CardSRSRecord> {
      $0.statusRaw != "new" && ($0.dueAt ?? sentinel) <= now
    }
    let descriptor = FetchDescriptor<CardSRSRecord>(
      predicate: predicate,
      sortBy: [SortDescriptor(\.dueAt, order: .forward)]
    )
    let candidates = try context.fetch(descriptor)
    // Set.contains inside #Predicate is a runtime-crash risk, so the owned-deck filter
    // is applied in memory instead of pushed into the SwiftData predicate.
    return candidates.filter { ownedDeckIds.contains($0.deckId) }
  }

  func reset() throws {
    let existingRecords = try context.fetch(FetchDescriptor<CardSRSRecord>())
    for record in existingRecords {
      context.delete(record)
    }
    try context.save()
  }
}
