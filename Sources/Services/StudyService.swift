import Foundation

final class StudyService {
  private let content: ContentStore
  private let srsStore: CardSRSStore
  private let activityStore: ActivityStore
  private let entitlements: EntitlementStore
  private let dateProvider: DateProvider

  init(
    content: ContentStore, srsStore: CardSRSStore, activityStore: ActivityStore,
    entitlements: EntitlementStore, dateProvider: DateProvider
  ) {
    self.content = content
    self.srsStore = srsStore
    self.activityStore = activityStore
    self.entitlements = entitlements
    self.dateProvider = dateProvider
  }

  func makeLearnSession(deckId: String, size: Int = 12) throws -> SessionEngine {
    let newCardIds = try newCardIds(forDeck: deckId)
    let batch = SRSQueueBuilder.learnBatch(newCardIds: newCardIds, size: size)
    let cards = try batch.map { try sessionCard(deckId: deckId, cardId: $0) }
    return SessionEngine(mode: .learn, cards: cards, now: { [dateProvider] in dateProvider.now })
  }

  func makeReviewSession() throws -> SessionEngine {
    let owned = try entitlements.ownedDeckIds(catalog: try content.catalog())
    let now = dateProvider.now
    let dueRecords = try srsStore.dueRecords(now: now, ownedDeckIds: owned)
    let entries = dueRecords.map {
      QueueEntry(cardId: $0.cardId, deckId: $0.deckId, state: SRSBridge.state(from: $0))
    }
    let queued = SRSQueueBuilder.reviewQueue(from: entries, now: now)
    let cards = queued.map { SessionCard(deckId: $0.deckId, cardId: $0.cardId, state: $0.state) }
    return SessionEngine(mode: .review, cards: cards, now: { [dateProvider] in dateProvider.now })
  }

  func makePracticeSession(deckId: String) throws -> SessionEngine {
    let deckCards = try content.cards(forDeck: deckId)
    let cards = try deckCards.map { try sessionCard(deckId: deckId, cardId: $0.id) }
    return SessionEngine(
      mode: .practice, cards: cards, now: { [dateProvider] in dateProvider.now })
  }

  func makeLearnMoreSession(size: Int = 5) throws -> SessionEngine {
    let catalog = try content.catalog()
    let owned = try entitlements.ownedDeckIds(catalog: catalog)

    var collected: [SessionCard] = []
    for country in catalog.countries {
      for deck in country.decks where owned.contains(deck.id) {
        if collected.count >= size { break }
        let newIds = try newCardIds(forDeck: deck.id)
        for cardId in newIds {
          if collected.count >= size { break }
          collected.append(try sessionCard(deckId: deck.id, cardId: cardId))
        }
      }
      if collected.count >= size { break }
    }

    return SessionEngine(
      mode: .learn, cards: collected, now: { [dateProvider] in dateProvider.now })
  }

  func commit(_ engine: SessionEngine) throws {
    let now = dateProvider.now
    for (card, grade) in engine.gradedResults {
      let existing = try srsStore.record(deckId: card.deckId, cardId: card.cardId)
      let currentState = existing.map { SRSBridge.state(from: $0) } ?? SRSState.newCard
      let newState = SRSEngine.apply(grade, to: currentState, now: now)
      try srsStore.upsert(
        deckId: card.deckId, cardId: card.cardId, statusRaw: newState.status.rawValue,
        easeFactor: newState.easeFactor, intervalDays: newState.intervalDays,
        repetitions: newState.repetitions, lapses: newState.lapses, dueAt: newState.dueAt,
        lastReviewedAt: now
      )
    }

    let summary = engine.summary()
    let cardsReviewed: Int
    let cardsLearned: Int
    switch engine.mode {
    case .review:
      cardsReviewed = engine.gradedResults.count
      cardsLearned = 0
    case .learn:
      cardsReviewed = 0
      cardsLearned = engine.gradedResults.count
    case .practice:
      cardsReviewed = 0
      cardsLearned = 0
    }

    try activityStore.addActivity(
      cardsReviewed: cardsReviewed, cardsLearned: cardsLearned,
      seconds: Int(summary.duration.rounded()), now: now
    )
  }

  private func newCardIds(forDeck deckId: String) throws -> [String] {
    let deckCards = try content.cards(forDeck: deckId)
    var newIds: [String] = []
    for card in deckCards {
      let record = try srsStore.record(deckId: deckId, cardId: card.id)
      if record == nil || record?.statusRaw == CardStatus.new.rawValue {
        newIds.append(card.id)
      }
    }
    return newIds
  }

  private func sessionCard(deckId: String, cardId: String) throws -> SessionCard {
    let record = try srsStore.record(deckId: deckId, cardId: cardId)
    let state = record.map { SRSBridge.state(from: $0) } ?? SRSState.newCard
    return SessionCard(deckId: deckId, cardId: cardId, state: state)
  }
}
