import Foundation

nonisolated enum SRSGrade: String, CaseIterable {
  case again, hard, good, easy
}

nonisolated enum CardStatus: String {
  case new, learning, review
}

nonisolated struct SRSState: Equatable {
  var status: CardStatus
  var easeFactor: Double
  var intervalDays: Double
  var repetitions: Int
  var lapses: Int
  var dueAt: Date?
}

extension SRSState {
  static let newCard = SRSState(
    status: .new, easeFactor: 2.5, intervalDays: 0, repetitions: 0, lapses: 0, dueAt: nil)
}
