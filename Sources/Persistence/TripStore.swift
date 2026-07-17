import Foundation
import SwiftData

final class TripStore {
  private let context: ModelContext

  init(context: ModelContext) {
    self.context = context
  }

  func activeTrip() throws -> TripProfileRecord? {
    var descriptor = FetchDescriptor<TripProfileRecord>(
      predicate: #Predicate { $0.isActive == true }
    )
    descriptor.fetchLimit = 1
    return try context.fetch(descriptor).first
  }

  @discardableResult
  func saveNewTrip(
    countryId: String,
    duration: String,
    scenarioIds: [String],
    accentRawValue: String,
    startDate: Date
  ) throws -> TripProfileRecord {
    let existingTrips = try context.fetch(FetchDescriptor<TripProfileRecord>())
    for trip in existingTrips where trip.isActive {
      trip.isActive = false
    }

    let record = TripProfileRecord(
      countryId: countryId,
      duration: duration,
      scenarioIds: scenarioIds,
      startDate: startDate,
      accentRawValue: accentRawValue,
      isActive: true
    )
    context.insert(record)
    try context.save()
    return record
  }

  func dayNumber(now: Date) throws -> Int? {
    guard let trip = try activeTrip() else { return nil }

    let calendar = Calendar.current
    let startOfTripDay = calendar.startOfDay(for: trip.startDate)
    let startOfNow = calendar.startOfDay(for: now)
    let days = calendar.dateComponents([.day], from: startOfTripDay, to: startOfNow).day ?? 0
    return max(1, days + 1)
  }

  /// Deactivates the current trip but KEEPS the record (trip history) — used by
  /// `AppState.startNewTrip()`, which must not touch owned packs or entitlements.
  func deactivateActiveTrip() throws {
    guard let trip = try activeTrip() else { return }
    trip.isActive = false
    try context.save()
  }

  func reset() throws {
    let existingTrips = try context.fetch(FetchDescriptor<TripProfileRecord>())
    for trip in existingTrips {
      context.delete(trip)
    }
    try context.save()
  }
}
