import SwiftUI

/// Root of the app shell — switches on `AppState.phase`. Both branches are temporary
/// placeholders: onboarding is replaced by T031, main by T030.
struct RootView: View {
  let appState: AppState

  @Environment(\.scenePhase) private var scenePhase

  init(appState: AppState) {
    self.appState = appState
    LaunchArguments.handle(services: appState.services)
    appState.refreshFromStore()
  }

  var body: some View {
    Group {
      switch appState.phase {
      case .onboarding:
        OnboardingFlowView(appState: appState, startAtCountryPicker: appState.isReonboarding)
      case .main:
        MainShellView()
      }
    }
    .environment(appState)
    .environment(\.accentTheme, appState.activeAccent)
    .onChange(of: scenePhase) { _, newPhase in
      guard newPhase == .active, appState.phase == .main else { return }
      Task {
        await rescheduleReviewNotification()
      }
    }
  }

  private func rescheduleReviewNotification() async {
    let services = appState.services
    do {
      let catalog = try services.contentStore.catalog()
      let owned = try services.entitlementStore.ownedDeckIds(catalog: catalog)
      let now = services.dateProvider.now

      var dueDates: [Date] = []
      for deckId in owned {
        let records = try services.cardSRSStore.records(forDeck: deckId)
        dueDates.append(
          contentsOf:
            records
            .filter { $0.statusRaw != "new" }
            .compactMap(\.dueAt)
        )
      }

      let forecast = NotificationsService.forecast(dueDates: dueDates, now: now)
      await services.notifications.rescheduleReviewNotification(
        dueCount: forecast?.count ?? 0, nextDueDate: forecast?.fireAt
      )
    } catch {
      await services.notifications.rescheduleReviewNotification(dueCount: 0, nextDueDate: nil)
    }
  }
}
