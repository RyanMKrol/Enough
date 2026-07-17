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
