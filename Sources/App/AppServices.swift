import SwiftData
import SwiftUI
import UserNotifications

/// The app's dependency container. Built once per process (`.live()` for the real app,
/// `.preview()` for tests/SwiftUI previews) and threaded through the environment.
final class AppServices {
  let dateProvider: DateProvider
  let contentStore: ContentStore
  let container: ModelContainer
  let tripStore: TripStore
  let entitlementStore: EntitlementStore
  let cardSRSStore: CardSRSStore
  let activityStore: ActivityStore
  let purchase: PurchaseProviding
  let audio: AudioService
  let study: StudyService
  let deckProgress: DeckProgressService
  let stats: StatsService
  let notifications: NotificationsService

  init(
    dateProvider: DateProvider,
    contentStore: ContentStore,
    container: ModelContainer,
    tripStore: TripStore,
    entitlementStore: EntitlementStore,
    cardSRSStore: CardSRSStore,
    activityStore: ActivityStore,
    purchase: PurchaseProviding,
    audio: AudioService,
    study: StudyService,
    deckProgress: DeckProgressService,
    stats: StatsService,
    notifications: NotificationsService
  ) {
    self.dateProvider = dateProvider
    self.contentStore = contentStore
    self.container = container
    self.tripStore = tripStore
    self.entitlementStore = entitlementStore
    self.cardSRSStore = cardSRSStore
    self.activityStore = activityStore
    self.purchase = purchase
    self.audio = audio
    self.study = study
    self.deckProgress = deckProgress
    self.stats = stats
    self.notifications = notifications
  }

  static func live() -> AppServices {
    // swiftlint:disable:next force_try
    let container = try! PersistenceStack.container()
    return makeGraph(container: container, notificationCenter: UNUserNotificationCenter.current())
  }

  static func preview() -> AppServices {
    // swiftlint:disable:next force_try
    let container = try! PersistenceStack.container(inMemory: true)
    return makeGraph(container: container, notificationCenter: NoopNotificationCenter())
  }

  private static func makeGraph(
    container: ModelContainer, notificationCenter: UserNotificationCentering
  ) -> AppServices {
    let dateProvider = AdjustableDateProvider()
    let contentStore = ContentStore()
    let context = ModelContext(container)
    context.autosaveEnabled = false

    let tripStore = TripStore(context: context)
    let entitlementStore = EntitlementStore(context: context)
    let cardSRSStore = CardSRSStore(context: context)
    let activityStore = ActivityStore(context: context)

    let catalog = try? contentStore.catalog()
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
    let notifications = NotificationsService(center: notificationCenter)

    return AppServices(
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
      notifications: notifications
    )
  }
}

extension EnvironmentValues {
  @Entry var services: AppServices = .preview()
}
