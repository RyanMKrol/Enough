import Foundation

nonisolated struct SplitMix64: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    self.state = seed
  }

  mutating func next() -> UInt64 {
    state &+= 0x9e37_79b9_7f4a_7c15
    var z = state
    z = (z ^ (z >> 30)) &* 0xbf58_476d_1ce4_e5b9
    z = (z ^ (z >> 27)) &* 0x94d0_49bb_1331_11eb
    return z ^ (z >> 31)
  }
}

nonisolated func fnv1a(_ s: String) -> UInt64 {
  var hash: UInt64 = 0xcbf2_9ce4_8422_2325
  for byte in s.utf8 {
    hash = (hash ^ UInt64(byte)) &* 0x0000_0100_0000_01b3
  }
  return hash
}

enum MCResultSheet: Equatable {
  case correct(intervalLabel: String)
  case incorrect(target: String, english: String)
}

@Observable
final class MCSessionViewModel {
  private let engine: SessionEngine
  private let services: AppServices

  private(set) var currentCardId: String?
  private(set) var target: String = ""
  private(set) var pronunciation: String = ""
  private var audioFile: String = ""
  private(set) var options: [String] = []
  private(set) var rowStates: [AnswerRowState] = []
  private(set) var resultSheet: MCResultSheet?
  private(set) var selectionCount: Int = 0
  private(set) var lastResult: AnswerRowState = .idle

  var progressText: String {
    let progress = engine.progress
    return "\(progress.done)/\(progress.total)"
  }

  var progressValue: Double {
    let progress = engine.progress
    return progress.total > 0 ? Double(progress.done) / Double(progress.total) : 0
  }

  var route: SessionRoute?

  init(engine: SessionEngine, services: AppServices) {
    self.engine = engine
    self.services = services
    services.audio.resetAutoPlay()
    loadCurrentCard()
  }

  func select(option: String) {
    guard let index = options.firstIndex(of: option), rowStates[index] == .idle else {
      return
    }
    guard let card = engine.current, let cardContent = try? cardContent(for: card) else {
      return
    }

    let isCorrect = option == cardContent.english
    selectionCount += 1

    if isCorrect {
      rowStates = rowStates.indices.map { rowIndex in
        rowIndex == index ? .correct : .faded
      }
      _ = engine.submitMultipleChoice(correct: true)
      let intervalLabel = SRSEngine.previewLabel(.good, for: card.state)
      lastResult = .correct
      resultSheet = .correct(intervalLabel: intervalLabel)
    } else {
      let correctIndex = options.firstIndex(of: cardContent.english)
      rowStates = rowStates.indices.map { rowIndex in
        if rowIndex == index { return .wrongShake }
        if rowIndex == correctIndex { return .correctOutline }
        return rowStates[rowIndex]
      }
      _ = engine.submitMultipleChoice(correct: false)
      lastResult = .wrongShake
      resultSheet = .incorrect(target: cardContent.target, english: cardContent.english)
    }
  }

  func advance() {
    resultSheet = nil
    engine.advance()

    if engine.isComplete {
      try? services.study.commit(engine)
      route = .complete
      return
    }

    loadCurrentCard()
  }

  func closeAndCommit() {
    try? services.study.commit(engine)
  }

  private func loadCurrentCard() {
    guard let card = engine.current, let cardContent = try? cardContent(for: card) else {
      currentCardId = nil
      return
    }

    currentCardId = card.cardId
    target = cardContent.target
    pronunciation = cardContent.pronunciation
    audioFile = cardContent.audio
    options = buildOptions(for: card, currentCard: cardContent)
    rowStates = Array(repeating: .idle, count: options.count)

    services.audio.autoPlayOnce(cardId: card.cardId, fileName: cardContent.audio)
  }

  func replayAudio() {
    services.audio.play(fileName: audioFile)
  }

  private func cardContent(for card: SessionCard) throws -> CardContent {
    let cards = try services.contentStore.cards(forDeck: card.deckId)
    guard let match = cards.first(where: { $0.id == card.cardId }) else {
      throw ContentStoreError.deckNotFound(card.deckId)
    }
    return match
  }

  private func buildOptions(for card: SessionCard, currentCard: CardContent) -> [String] {
    var candidates = deckCardsExcludingCurrent(deckId: card.deckId, currentCardId: card.cardId)

    if candidates.count < 3 {
      candidates.append(
        contentsOf: fallbackCandidates(
          deckId: card.deckId, currentCardId: card.cardId, excluding: candidates))
    }

    candidates.sort { $0.id < $1.id }

    var generator = SplitMix64(seed: fnv1a(card.cardId))
    let distractorCount = min(3, candidates.count)
    let distractors = Array(candidates.shuffled(using: &generator).prefix(distractorCount))

    var opts = [currentCard.english] + distractors.map(\.english)
    opts.shuffle(using: &generator)
    return opts
  }

  private func deckCardsExcludingCurrent(deckId: String, currentCardId: String) -> [CardContent] {
    guard let deckCards = try? services.contentStore.cards(forDeck: deckId) else {
      return []
    }
    return deckCards.filter { $0.id != currentCardId }
  }

  private func fallbackCandidates(
    deckId: String, currentCardId: String, excluding: [CardContent]
  ) -> [CardContent] {
    guard let catalog = try? services.contentStore.catalog() else {
      return []
    }
    let excludedIds = Set(excluding.map(\.id) + [currentCardId])

    guard
      let country = catalog.countries.first(where: { country in
        country.decks.contains(where: { $0.id == deckId })
      })
    else {
      return []
    }

    var collected: [CardContent] = []
    for deck in country.decks where deck.id != deckId {
      guard let deckCards = try? services.contentStore.cards(forDeck: deck.id) else { continue }
      for cardContent in deckCards where !excludedIds.contains(cardContent.id) {
        collected.append(cardContent)
      }
    }
    return collected
  }
}
