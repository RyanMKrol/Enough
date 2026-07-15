import Foundation

final class DeckProgressService {
  struct DeckProgress: Equatable {
    let deckId: String
    let total: Int
    let learned: Int
    let newCount: Int
    let learning: Int
    // swiftlint:disable:next inclusive_language
    let mastered: Int
    let dueNow: Int
    let strength: Int
  }

  private let content: ContentStore
  private let srsStore: CardSRSStore
  private let entitlements: EntitlementStore
  private let dateProvider: DateProvider

  init(
    content: ContentStore, srsStore: CardSRSStore, entitlements: EntitlementStore,
    dateProvider: DateProvider
  ) {
    self.content = content
    self.srsStore = srsStore
    self.entitlements = entitlements
    self.dateProvider = dateProvider
  }

  func progress(forDeck id: String) throws -> DeckProgress {
    let deckInfo = try content.deck(id)
    let records = try srsStore.records(forDeck: id)
    let now = dateProvider.now

    let learnedRecords = records.filter { $0.statusRaw != CardStatus.new.rawValue }
    let learning = records.filter { $0.statusRaw == CardStatus.learning.rawValue }.count
    // swiftlint:disable:next inclusive_language
    let mastered = records.filter { SRSEngine.isMastered(SRSBridge.state(from: $0)) }.count
    let dueNow = records.filter { SRSEngine.isDue(SRSBridge.state(from: $0), now: now) }.count
    let learned = learnedRecords.count

    return DeckProgress(
      deckId: id,
      total: deckInfo.cardCount,
      learned: learned,
      newCount: deckInfo.cardCount - learned,
      learning: learning,
      mastered: mastered,
      dueNow: dueNow,
      strength: strength(learned: learned, dueNow: dueNow)
    )
  }

  func totalDue() throws -> Int {
    try totals().due
  }

  // swiftlint:disable:next large_tuple
  func totals() throws -> (due: Int, learning: Int, mastered: Int) {
    let owned = try entitlements.ownedDeckIds(catalog: try content.catalog())
    let now = dateProvider.now
    var due = 0
    var learning = 0
    // swiftlint:disable:next inclusive_language
    var mastered = 0

    for deckId in owned {
      let records = try srsStore.records(forDeck: deckId)
      for record in records {
        let state = SRSBridge.state(from: record)
        if SRSEngine.isDue(state, now: now) { due += 1 }
        if record.statusRaw == CardStatus.learning.rawValue { learning += 1 }
        if SRSEngine.isMastered(state) { mastered += 1 }
      }
    }

    return (due: due, learning: learning, mastered: mastered)
  }

  func wordsLearned() throws -> Int {
    let owned = try entitlements.ownedDeckIds(catalog: try content.catalog())
    var learned = 0

    for deckId in owned {
      let records = try srsStore.records(forDeck: deckId)
      learned += records.filter { $0.statusRaw != CardStatus.new.rawValue }.count
    }

    return learned
  }

  private func strength(learned: Int, dueNow: Int) -> Int {
    if learned == 0 { return 0 }
    if dueNow == 0 { return 3 }
    if dueNow * 2 > learned { return 1 }
    return 2
  }
}
