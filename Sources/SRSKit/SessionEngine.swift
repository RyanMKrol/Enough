import Foundation

nonisolated struct SessionCard: Equatable {
  let deckId: String
  let cardId: String
  var state: SRSState
}

nonisolated enum SessionMode: Equatable {
  case learn, review, practice
}

nonisolated struct SessionSummary: Equatable {
  let cardsCompleted: Int
  let correctCount: Int
  let duration: TimeInterval
  let mode: SessionMode
}

nonisolated final class SessionEngine {
  let mode: SessionMode
  private var queue: [SessionCard]
  private var index: Int = 0
  private let startedAt: Date
  private let now: () -> Date
  private var firstAttemptGrade: [String: SRSGrade] = [:]
  private var completedIds: Set<String> = []
  private let uniqueKeys: [String]

  init(mode: SessionMode, cards: [SessionCard], now: @escaping () -> Date) {
    self.mode = mode
    self.queue = cards
    self.now = now
    self.startedAt = now()

    var seen = Set<String>()
    var order: [String] = []
    for card in cards {
      let key = Self.key(card)
      if !seen.contains(key) {
        seen.insert(key)
        order.append(key)
      }
    }
    self.uniqueKeys = order
  }

  private static func key(_ card: SessionCard) -> String {
    "\(card.deckId)/\(card.cardId)"
  }

  var current: SessionCard? {
    while index < queue.count {
      let card = queue[index]
      if completedIds.contains(Self.key(card)) {
        index += 1
        continue
      }
      return card
    }
    return nil
  }

  var progress: (done: Int, total: Int) {
    (completedIds.count, uniqueKeys.count)
  }

  var isComplete: Bool {
    completedIds.count == uniqueKeys.count
  }

  var gradedResults: [(card: SessionCard, grade: SRSGrade)] {
    if mode == .practice {
      return []
    }
    var byKey: [String: SessionCard] = [:]
    for card in queue {
      byKey[Self.key(card)] = card
    }
    return uniqueKeys.compactMap { key in
      guard let grade = firstAttemptGrade[key], let card = byKey[key] else { return nil }
      return (card: card, grade: grade)
    }
  }

  func submitMultipleChoice(correct: Bool) -> SRSGrade? {
    guard mode != .review, let card = current else { return nil }
    let key = Self.key(card)

    let isFirstAttempt = firstAttemptGrade[key] == nil
    if isFirstAttempt {
      firstAttemptGrade[key] = correct ? .good : .again
    }

    if correct {
      completedIds.insert(key)
    } else {
      let remaining = queue.count - index - 1
      let offset = SRSQueueBuilder.requeuePosition(queueLength: remaining)
      let insertAt = min(index + 1 + offset, queue.count)
      queue.insert(card, at: insertAt)
    }

    if isFirstAttempt {
      return mode == .learn ? firstAttemptGrade[key] : nil
    }
    return nil
  }

  func submitGrade(_ grade: SRSGrade) {
    guard mode == .review, let card = current else { return }
    let key = Self.key(card)
    if firstAttemptGrade[key] == nil {
      firstAttemptGrade[key] = grade
    }
    completedIds.insert(key)
  }

  func advance() {
    index += 1
  }

  func summary() -> SessionSummary {
    let correctCount: Int
    switch mode {
    case .learn, .practice:
      correctCount = firstAttemptGrade.values.filter { $0 == .good }.count
    case .review:
      correctCount = firstAttemptGrade.values.filter { $0 == .good || $0 == .easy }.count
    }
    return SessionSummary(
      cardsCompleted: progress.done,
      correctCount: correctCount,
      duration: now().timeIntervalSince(startedAt),
      mode: mode
    )
  }
}
