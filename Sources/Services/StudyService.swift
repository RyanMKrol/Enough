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
    let recordsById = try recordsById(forDeck: deckId)
    let newCardIds = try newCardIds(forDeck: deckId, recordsById: recordsById)
    let batch = SRSQueueBuilder.learnBatch(newCardIds: newCardIds, size: size)
    let cards = batch.map { sessionCard(deckId: deckId, cardId: $0, recordsById: recordsById) }
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
    let recordsById = try recordsById(forDeck: deckId)
    let cards = deckCards.map {
      sessionCard(deckId: deckId, cardId: $0.id, recordsById: recordsById)
    }
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
        let recordsById = try recordsById(forDeck: deck.id)
        let newIds = try newCardIds(forDeck: deck.id, recordsById: recordsById)
        for cardId in newIds {
          if collected.count >= size { break }
          collected.append(sessionCard(deckId: deck.id, cardId: cardId, recordsById: recordsById))
        }
      }
      if collected.count >= size { break }
    }

    return SessionEngine(
      mode: .learn, cards: collected, now: { [dateProvider] in dateProvider.now })
  }

  func commit(_ engine: SessionEngine) throws {
    let now = dateProvider.now
    let gradedResults = engine.gradedResults
    let deckIds = Set(gradedResults.map(\.card.deckId))
    let existingByKey = Dictionary(
      uniqueKeysWithValues: try srsStore.records(forDecks: deckIds).map {
        ("\($0.deckId)|\($0.cardId)", $0)
      })

    let updates = gradedResults.map { card, grade -> CardSRSStore.Update in
      let existing = existingByKey["\(card.deckId)|\(card.cardId)"]
      let currentState = existing.map { SRSBridge.state(from: $0) } ?? SRSState.newCard
      let newState = SRSEngine.apply(grade, to: currentState, now: now)
      return CardSRSStore.Update(
        deckId: card.deckId, cardId: card.cardId, statusRaw: newState.status.rawValue,
        easeFactor: newState.easeFactor, intervalDays: newState.intervalDays,
        repetitions: newState.repetitions, lapses: newState.lapses, dueAt: newState.dueAt,
        lastReviewedAt: now
      )
    }
    try srsStore.upsertBatch(updates)

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

  private func recordsById(forDeck deckId: String) throws -> [String: CardSRSRecord] {
    Dictionary(uniqueKeysWithValues: try srsStore.records(forDeck: deckId).map { ($0.cardId, $0) })
  }

  private func newCardIds(
    forDeck deckId: String, recordsById: [String: CardSRSRecord]
  ) throws -> [String] {
    let deckCards = try content.cards(forDeck: deckId)
    return deckCards.filter { card in
      let record = recordsById[card.id]
      return record == nil || record?.statusRaw == CardStatus.new.rawValue
    }.map(\.id)
  }

  private func sessionCard(
    deckId: String, cardId: String, recordsById: [String: CardSRSRecord]
  ) -> SessionCard {
    let state = recordsById[cardId].map { SRSBridge.state(from: $0) } ?? SRSState.newCard
    return SessionCard(deckId: deckId, cardId: cardId, state: state)
  }
}
