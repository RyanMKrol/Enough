import SwiftData
import XCTest

@testable import Enough

@MainActor
final class StudyServiceTests: XCTestCase {
  private struct FixedDateProvider: DateProvider {
    let now: Date
  }

  private struct Env {
    let content: ContentStore
    let srsStore: CardSRSStore
    let activityStore: ActivityStore
    let entitlements: EntitlementStore
    let now: Date
    let service: StudyService
  }

  private func makeEnv(now: Date = Date(timeIntervalSince1970: 1_700_000_000)) throws -> Env {
    let container = try PersistenceStack.container(inMemory: true)
    let context = ModelContext(container)
    let content = ContentStore()
    let srsStore = CardSRSStore(context: context)
    let activityStore = ActivityStore(context: context)
    let entitlements = EntitlementStore(context: context)

    try entitlements.grant(productId: "jp-greetings", kind: "deck", now: now)

    let service = StudyService(
      content: content, srsStore: srsStore, activityStore: activityStore,
      entitlements: entitlements, dateProvider: FixedDateProvider(now: now)
    )

    return Env(
      content: content, srsStore: srsStore, activityStore: activityStore,
      entitlements: entitlements, now: now, service: service
    )
  }

  func testMakeLearnSessionReturnsFirstNCardsInDeckOrder() throws {
    let env = try makeEnv()
    let expectedIds = try env.content.cards(forDeck: "jp-greetings").prefix(3).map(\.id)

    let engine = try env.service.makeLearnSession(deckId: "jp-greetings", size: 3)

    XCTAssertEqual(engine.mode, .learn)
    var seenIds: [String] = []
    while !engine.isComplete {
      guard let card = engine.current else { break }
      seenIds.append(card.cardId)
      _ = engine.submitMultipleChoice(correct: true)
      engine.advance()
    }
    XCTAssertEqual(seenIds, expectedIds)
  }

  func testLearnSessionEndToEndCommit() throws {
    let env = try makeEnv()
    let allIds = try env.content.cards(forDeck: "jp-greetings").prefix(3).map(\.id)

    let engine = try env.service.makeLearnSession(deckId: "jp-greetings", size: 3)
    XCTAssertEqual(engine.mode, .learn)

    // Card 1: correct
    XCTAssertEqual(engine.current?.cardId, allIds[0])
    XCTAssertEqual(engine.submitMultipleChoice(correct: true), .good)
    engine.advance()

    // Card 2: wrong then correct
    XCTAssertEqual(engine.current?.cardId, allIds[1])
    XCTAssertEqual(engine.submitMultipleChoice(correct: false), .again)
    engine.advance()

    // Card 3: correct
    XCTAssertEqual(engine.current?.cardId, allIds[2])
    XCTAssertEqual(engine.submitMultipleChoice(correct: true), .good)
    engine.advance()

    // Requeued card 2: correct on second attempt
    XCTAssertEqual(engine.current?.cardId, allIds[1])
    XCTAssertNil(engine.submitMultipleChoice(correct: true))
    engine.advance()

    XCTAssertTrue(engine.isComplete)
    let summary = engine.summary()

    try env.service.commit(engine)

    let record1 = try env.srsStore.record(deckId: "jp-greetings", cardId: allIds[0])
    let record2 = try env.srsStore.record(deckId: "jp-greetings", cardId: allIds[1])
    let record3 = try env.srsStore.record(deckId: "jp-greetings", cardId: allIds[2])

    XCTAssertNotNil(record1)
    XCTAssertNotNil(record2)
    XCTAssertNotNil(record3)

    XCTAssertEqual(record1?.statusRaw, CardStatus.learning.rawValue)
    XCTAssertEqual(record1?.intervalDays, 1.0)
    XCTAssertEqual(record3?.statusRaw, CardStatus.learning.rawValue)
    XCTAssertEqual(record3?.intervalDays, 1.0)

    XCTAssertEqual(record2?.statusRaw, CardStatus.learning.rawValue)
    XCTAssertEqual(record2?.intervalDays ?? -1, 1.0 / 1440.0, accuracy: 0.0000001)
    XCTAssertEqual(record2?.easeFactor ?? -1, 2.3, accuracy: 0.0000001)

    XCTAssertEqual(record1?.lastReviewedAt, env.now)
    XCTAssertEqual(record2?.lastReviewedAt, env.now)
    XCTAssertEqual(record3?.lastReviewedAt, env.now)

    let activities = try env.activityStore.all()
    XCTAssertEqual(activities.count, 1)
    XCTAssertEqual(activities[0].cardsLearned, 3)
    XCTAssertEqual(activities[0].cardsReviewed, 0)
    XCTAssertEqual(activities[0].secondsStudied, Int(summary.duration.rounded()))
  }

  func testMakeLearnSessionAfterCommitReturnsNextCards() throws {
    let env = try makeEnv()
    let allIds = try env.content.cards(forDeck: "jp-greetings").map(\.id)

    let firstEngine = try env.service.makeLearnSession(deckId: "jp-greetings", size: 3)
    while !firstEngine.isComplete {
      guard firstEngine.current != nil else { break }
      _ = firstEngine.submitMultipleChoice(correct: true)
      firstEngine.advance()
    }
    try env.service.commit(firstEngine)

    let secondEngine = try env.service.makeLearnSession(deckId: "jp-greetings", size: 3)
    var seenIds: [String] = []
    while !secondEngine.isComplete {
      guard let card = secondEngine.current else { break }
      seenIds.append(card.cardId)
      _ = secondEngine.submitMultipleChoice(correct: true)
      secondEngine.advance()
    }
    XCTAssertEqual(seenIds, Array(allIds[3..<6]))
  }

  func testReviewSessionOrdersByMostOverdueAndCommits() throws {
    let env = try makeEnv()
    let cardIds = try env.content.cards(forDeck: "jp-greetings").map(\.id)

    // due 2h ago
    try env.srsStore.upsert(
      deckId: "jp-greetings", cardId: cardIds[0], statusRaw: "review", easeFactor: 2.5,
      intervalDays: 5, repetitions: 1, lapses: 0, dueAt: env.now.addingTimeInterval(-7200),
      lastReviewedAt: nil
    )
    // due 1h ago
    try env.srsStore.upsert(
      deckId: "jp-greetings", cardId: cardIds[1], statusRaw: "review", easeFactor: 2.5,
      intervalDays: 5, repetitions: 1, lapses: 0, dueAt: env.now.addingTimeInterval(-3600),
      lastReviewedAt: nil
    )
    // future, not due
    try env.srsStore.upsert(
      deckId: "jp-greetings", cardId: cardIds[2], statusRaw: "review", easeFactor: 2.5,
      intervalDays: 5, repetitions: 1, lapses: 0, dueAt: env.now.addingTimeInterval(3600),
      lastReviewedAt: nil
    )

    let engine = try env.service.makeReviewSession()
    XCTAssertEqual(engine.mode, .review)
    XCTAssertEqual(engine.progress.total, 2)

    XCTAssertEqual(engine.current?.cardId, cardIds[0])
    engine.submitGrade(.good)
    engine.advance()

    XCTAssertEqual(engine.current?.cardId, cardIds[1])
    engine.submitGrade(.again)
    engine.advance()

    XCTAssertTrue(engine.isComplete)

    try env.service.commit(engine)

    let record0 = try env.srsStore.record(deckId: "jp-greetings", cardId: cardIds[0])
    let record1 = try env.srsStore.record(deckId: "jp-greetings", cardId: cardIds[1])

    let goodStartState = SRSState(
      status: .review, easeFactor: 2.5, intervalDays: 5, repetitions: 1, lapses: 0,
      dueAt: env.now.addingTimeInterval(-7200))
    let againStartState = SRSState(
      status: .review, easeFactor: 2.5, intervalDays: 5, repetitions: 1, lapses: 0,
      dueAt: env.now.addingTimeInterval(-3600))
    let expectedGood = SRSEngine.apply(.good, to: goodStartState, now: env.now)
    let expectedAgain = SRSEngine.apply(.again, to: againStartState, now: env.now)

    XCTAssertEqual(record0?.statusRaw, expectedGood.status.rawValue)
    XCTAssertEqual(record0?.intervalDays, expectedGood.intervalDays)
    XCTAssertEqual(record1?.statusRaw, expectedAgain.status.rawValue)
    XCTAssertEqual(record1?.intervalDays ?? -1, expectedAgain.intervalDays, accuracy: 0.0000001)

    let activities = try env.activityStore.all()
    XCTAssertEqual(activities.count, 1)
    XCTAssertEqual(activities[0].cardsReviewed, 2)
    XCTAssertEqual(activities[0].cardsLearned, 0)
  }

  func testPracticeSessionCoversAllCardsAndLogsSecondsWithoutRecords() throws {
    let env = try makeEnv()
    let engine = try env.service.makePracticeSession(deckId: "jp-greetings")

    XCTAssertEqual(engine.mode, .practice)
    XCTAssertEqual(engine.progress.total, 30)

    while !engine.isComplete {
      guard engine.current != nil else { break }
      _ = engine.submitMultipleChoice(correct: true)
      engine.advance()
    }
    XCTAssertTrue(engine.isComplete)
    let summary = engine.summary()

    try env.service.commit(engine)

    let records = try env.srsStore.records(forDeck: "jp-greetings")
    XCTAssertTrue(records.isEmpty)

    let activities = try env.activityStore.all()
    XCTAssertEqual(activities.count, 1)
    XCTAssertEqual(activities[0].cardsReviewed, 0)
    XCTAssertEqual(activities[0].cardsLearned, 0)
    XCTAssertEqual(activities[0].secondsStudied, Int(summary.duration.rounded()))
  }

  func testLearnMoreSessionOnlyPullsFromOwnedDecks() throws {
    let env = try makeEnv()

    let engine = try env.service.makeLearnMoreSession(size: 5)
    XCTAssertEqual(engine.mode, .learn)
    XCTAssertEqual(engine.progress.total, 5)

    while !engine.isComplete {
      guard let card = engine.current else { break }
      XCTAssertEqual(card.deckId, "jp-greetings")
      _ = engine.submitMultipleChoice(correct: true)
      engine.advance()
    }
    XCTAssertTrue(engine.isComplete)
  }
}
