import Foundation

enum ReviewGradeFeedback: Equatable {
  case remembered
  case forgotten
}

@Observable
final class ReviewSessionViewModel {
  private let engine: SessionEngine
  private let services: AppServices

  private(set) var currentCardId: String?
  var isRevealed: Bool = false
  private(set) var previews: [GradeChoice: String] = [:]
  private(set) var gradeCount: Int = 0
  var lastGradeFeedback: ReviewGradeFeedback?
  private var audioFile: String = ""

  var route: SessionRoute?

  var progressText: String {
    let progress = engine.progress
    return "\(progress.done)/\(progress.total)"
  }

  var progressValue: Double {
    let progress = engine.progress
    return progress.total > 0 ? Double(progress.done) / Double(progress.total) : 0
  }

  init(engine: SessionEngine, services: AppServices) {
    self.engine = engine
    self.services = services
    services.audio.resetAutoPlay()
    loadCurrentCard()
  }

  func grade(_ choice: GradeChoice) {
    guard let srsGrade = Self.srsGrade(for: choice) else { return }
    gradeCount += 1
    lastGradeFeedback = choice == .again ? .forgotten : .remembered
    engine.submitGrade(srsGrade)
    advance()
  }

  func closeAndCommit() {
    try? services.study.commit(engine)
    services.audio.sessionEnded()
  }

  func replayAudio() {
    services.audio.play(fileName: audioFile)
  }

  private func advance() {
    engine.advance()
    isRevealed = false

    if engine.isComplete {
      try? services.study.commit(engine)
      services.audio.sessionEnded()
      route = .complete
      return
    }

    loadCurrentCard()
  }

  private func loadCurrentCard() {
    guard let card = engine.current, let cardContent = try? cardContent(for: card) else {
      currentCardId = nil
      previews = [:]
      return
    }

    currentCardId = card.cardId
    audioFile = cardContent.audio
    previews = Self.buildPreviews(for: card.state)

    services.audio.autoPlayOnce(cardId: card.cardId, fileName: cardContent.audio)
  }

  private func cardContent(for card: SessionCard) throws -> CardContent {
    let cards = try services.contentStore.cards(forDeck: card.deckId)
    guard let match = cards.first(where: { $0.id == card.cardId }) else {
      throw ContentStoreError.deckNotFound(card.deckId)
    }
    return match
  }

  private static func buildPreviews(for state: SRSState) -> [GradeChoice: String] {
    var result: [GradeChoice: String] = [:]
    for choice in GradeChoice.allCases {
      guard let srsGrade = srsGrade(for: choice) else { continue }
      result[choice] = SRSEngine.previewLabel(srsGrade, for: state)
    }
    return result
  }

  private static func srsGrade(for choice: GradeChoice) -> SRSGrade? {
    switch choice {
    case .again: return .again
    case .hard: return .hard
    case .good: return .good
    case .easy: return .easy
    }
  }
}
