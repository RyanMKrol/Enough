import Foundation

enum SRSBridge {
  static func state(from record: CardSRSRecord) -> SRSState {
    SRSState(
      status: CardStatus(rawValue: record.statusRaw) ?? .new,
      easeFactor: record.easeFactor,
      intervalDays: record.intervalDays,
      repetitions: record.repetitions,
      lapses: record.lapses,
      dueAt: record.dueAt
    )
  }

  static func apply(_ state: SRSState, to record: CardSRSRecord, reviewedAt: Date) {
    record.statusRaw = state.status.rawValue
    record.easeFactor = state.easeFactor
    record.intervalDays = state.intervalDays
    record.repetitions = state.repetitions
    record.lapses = state.lapses
    record.dueAt = state.dueAt
    record.lastReviewedAt = reviewedAt
  }
}
