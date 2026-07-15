import Foundation
import SwiftData

final class ActivityStore {
  private let context: ModelContext

  init(context: ModelContext) {
    self.context = context
  }

  func record(for day: Date) throws -> DailyActivityRecord? {
    let startOfDay = Calendar.current.startOfDay(for: day)
    var descriptor = FetchDescriptor<DailyActivityRecord>(
      predicate: #Predicate { $0.day == startOfDay }
    )
    descriptor.fetchLimit = 1
    return try context.fetch(descriptor).first
  }

  @discardableResult
  func addActivity(
    cardsReviewed: Int, cardsLearned: Int, seconds: Int, now: Date
  ) throws -> DailyActivityRecord {
    let today = Calendar.current.startOfDay(for: now)
    if let existing = try record(for: today) {
      existing.cardsReviewed += cardsReviewed
      existing.cardsLearned += cardsLearned
      existing.secondsStudied += seconds
      try context.save()
      return existing
    }

    let record = DailyActivityRecord(
      day: today,
      cardsReviewed: cardsReviewed,
      cardsLearned: cardsLearned,
      secondsStudied: seconds
    )
    context.insert(record)
    try context.save()
    return record
  }

  func all() throws -> [DailyActivityRecord] {
    let descriptor = FetchDescriptor<DailyActivityRecord>(
      sortBy: [SortDescriptor(\.day, order: .forward)]
    )
    return try context.fetch(descriptor)
  }

  func reset() throws {
    let existingRecords = try context.fetch(FetchDescriptor<DailyActivityRecord>())
    for record in existingRecords {
      context.delete(record)
    }
    try context.save()
  }
}
