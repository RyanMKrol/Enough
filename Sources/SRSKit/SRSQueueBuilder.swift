import Foundation

nonisolated struct QueueEntry: Equatable {
  let cardId: String
  let deckId: String
  var state: SRSState
}

nonisolated enum SRSQueueBuilder {
  static func reviewQueue(
    from entries: [QueueEntry], now: Date, limit: Int? = nil
  ) -> [QueueEntry] {
    let due = entries.enumerated().filter { SRSEngine.isDue($0.element.state, now: now) }
    let sorted = due.sorted { lhs, rhs in
      let lhsDue = lhs.element.state.dueAt ?? .distantFuture
      let rhsDue = rhs.element.state.dueAt ?? .distantFuture
      if lhsDue != rhsDue {
        return lhsDue < rhsDue
      }
      return lhs.offset < rhs.offset
    }
    let ordered = sorted.map(\.element)
    if let limit {
      return Array(ordered.prefix(limit))
    }
    return ordered
  }

  static func learnBatch(newCardIds: [String], size: Int = 12) -> [String] {
    Array(newCardIds.prefix(size))
  }

  static func requeuePosition(queueLength: Int) -> Int {
    min(queueLength, 3)
  }
}
