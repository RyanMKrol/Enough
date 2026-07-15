import Foundation

nonisolated enum SRSEngine {
  private static let easeFloor = 1.3

  static func apply(_ grade: SRSGrade, to state: SRSState, now: Date) -> SRSState {
    var next: SRSState
    switch grade {
    case .again: next = applyAgain(state)
    case .hard: next = applyHard(state)
    case .good: next = applyGood(state)
    case .easy: next = applyEasy(state)
    }

    next.easeFactor = max(next.easeFactor, easeFloor)
    next.dueAt = now.addingTimeInterval(next.intervalDays * 86_400)
    return next
  }

  private static func applyAgain(_ state: SRSState) -> SRSState {
    var next = state
    if state.status == .review {
      next.lapses += 1
    }
    next.repetitions = 0
    next.status = .learning
    next.intervalDays = 1.0 / 1440.0
    next.easeFactor = state.easeFactor - 0.2
    return next
  }

  private static func applyHard(_ state: SRSState) -> SRSState {
    var next = state
    next.easeFactor = state.easeFactor - 0.15
    next.status = state.status == .new ? .learning : state.status
    if state.intervalDays < 1 {
      next.intervalDays = 1.0
    } else if state.status == .learning {
      next.intervalDays = state.intervalDays
    } else {
      next.intervalDays = (state.intervalDays * 1.2).rounded(.up)
    }
    return next
  }

  private static func applyGood(_ state: SRSState) -> SRSState {
    var next = state
    next.repetitions = state.repetitions + 1
    switch state.status {
    case .new:
      next.status = .learning
      next.intervalDays = 1
    case .learning:
      if state.intervalDays <= 1 {
        next.status = .learning
        next.intervalDays = 3
      } else {
        next.status = .review
        next.intervalDays = (3 * state.easeFactor).rounded()
      }
    case .review:
      next.status = .review
      next.intervalDays = (state.intervalDays * state.easeFactor).rounded()
    }
    return next
  }

  private static func applyEasy(_ state: SRSState) -> SRSState {
    var next = state
    next.repetitions = state.repetitions + 1
    next.easeFactor = state.easeFactor + 0.15
    if state.status == .new || (state.status == .learning && state.intervalDays <= 1) {
      next.status = .review
      next.intervalDays = 6
    } else {
      next.status = .review
      next.intervalDays = (state.intervalDays * state.easeFactor * 1.3).rounded()
    }
    return next
  }
}
