import SwiftData
import XCTest

@testable import Enough

@MainActor
final class ReviewSessionViewModelTests: XCTestCase {
  private struct FixedDateProvider: DateProvider {
    let now: Date
  }

  private struct Env {
    let services: AppServices
    let cardIds: [String]
  }

  private func makeEnv(now: Date, dueCardCount: Int = 3) throws -> Env {
    let container = try PersistenceStack.container(inMemory: true)
    let context = ModelContext(container)
    context.autosaveEnabled = false

    let dateProvider = FixedDateProvider(now: now)
    let contentStore = ContentStore()
    let entitlementStore = EntitlementStore(context: context)
    let cardSRSStore = CardSRSStore(context: context)
    let activityStore = ActivityStore(context: context)
    let tripStore = TripStore(context: context)
    let catalog = try contentStore.catalog()
    let purchase = StubPurchaseService(entitlements: entitlementStore, catalog: catalog)
    let audio = AudioService(content: contentStore)
    let study = StudyService(
      content: contentStore, srsStore: cardSRSStore, activityStore: activityStore,
      entitlements: entitlementStore, dateProvider: dateProvider
    )
    let deckProgress = DeckProgressService(
      content: contentStore, srsStore: cardSRSStore, entitlements: entitlementStore,
      dateProvider: dateProvider
    )
    let stats = StatsService(activityStore: activityStore, dateProvider: dateProvider)

    try entitlementStore.grant(productId: "jp-greetings", kind: "deck", now: now)

    let deckCards = try contentStore.cards(forDeck: "jp-greetings").prefix(dueCardCount)
    let cardIds = deckCards.map(\.id)
    let pastDue = now.addingTimeInterval(-3_600)
    for cardId in cardIds {
      try cardSRSStore.upsert(
        deckId: "jp-greetings", cardId: cardId, statusRaw: CardStatus.learning.rawValue,
        easeFactor: 2.5, intervalDays: 1, repetitions: 1, lapses: 0, dueAt: pastDue,
        lastReviewedAt: pastDue
      )
    }

    let services = AppServices(
      dateProvider: dateProvider,
      contentStore: contentStore,
      container: container,
      tripStore: tripStore,
      entitlementStore: entitlementStore,
      cardSRSStore: cardSRSStore,
      activityStore: activityStore,
      purchase: purchase,
      audio: audio,
      study: study,
      deckProgress: deckProgress,
      stats: stats,
      notifications: NotificationsService(center: NoopNotificationCenter())
    )

    return Env(services: services, cardIds: cardIds)
  }

  func testPreviewsMatchEngineComputedLabelsForLearningCard() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let env = try makeEnv(now: now)
    let engine = try env.services.study.makeReviewSession()
    let vm = ReviewSessionViewModel(engine: engine, services: env.services)

    XCTAssertEqual(vm.previews[.again], SRSEngine.previewLabel(.again, for: .learningOneDay))
    XCTAssertEqual(vm.previews[.hard], SRSEngine.previewLabel(.hard, for: .learningOneDay))
    XCTAssertEqual(vm.previews[.good], SRSEngine.previewLabel(.good, for: .learningOneDay))
    XCTAssertEqual(vm.previews[.easy], SRSEngine.previewLabel(.easy, for: .learningOneDay))

    XCTAssertEqual(vm.previews[.again], "<1 min")
    XCTAssertEqual(vm.previews[.hard], "1 day")
    XCTAssertEqual(vm.previews[.good], "3 days")
    XCTAssertEqual(vm.previews[.easy], "6 days")
  }

  func testGradeGoodRecordsResultAndMovesToNextCardHidden() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let env = try makeEnv(now: now)
    let engine = try env.services.study.makeReviewSession()
    let vm = ReviewSessionViewModel(engine: engine, services: env.services)

    let firstCardId = vm.currentCardId
    vm.isRevealed = true

    vm.grade(.good)

    XCTAssertEqual(vm.progressText, "1/3")
    XCTAssertFalse(vm.isRevealed)
    XCTAssertNotEqual(vm.currentCardId, firstCardId)
  }

  func testGradingFinalCardCommitsAndSetsCompleteRoute() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let env = try makeEnv(now: now)
    let engine = try env.services.study.makeReviewSession()
    let vm = ReviewSessionViewModel(engine: engine, services: env.services)

    vm.isRevealed = true
    vm.grade(.good)
    vm.isRevealed = true
    vm.grade(.good)
    vm.isRevealed = true
    vm.grade(.good)

    XCTAssertEqual(vm.route, .complete)

    let records = try env.services.cardSRSStore.records(forDeck: "jp-greetings")
    XCTAssertEqual(records.count, 3)
    for record in records {
      XCTAssertEqual(record.statusRaw, CardStatus.learning.rawValue)
      XCTAssertEqual(record.intervalDays, 3)
    }
  }

  func testCloseAndCommitAfterGradingOnePersistsOnlyThatResult() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let env = try makeEnv(now: now)
    let engine = try env.services.study.makeReviewSession()
    let vm = ReviewSessionViewModel(engine: engine, services: env.services)

    let firstCardId = vm.currentCardId!
    vm.isRevealed = true
    vm.grade(.good)

    vm.closeAndCommit()

    let records = try env.services.cardSRSStore.records(forDeck: "jp-greetings")
    XCTAssertEqual(records.count, 3)
    let updated = records.filter { $0.lastReviewedAt == now }
    XCTAssertEqual(updated.count, 1)
    XCTAssertEqual(updated.first?.cardId, firstCardId)
  }
}

extension SRSState {
  fileprivate static let learningOneDay = SRSState(
    status: .learning, easeFactor: 2.5, intervalDays: 1, repetitions: 1, lapses: 0, dueAt: nil)
}
