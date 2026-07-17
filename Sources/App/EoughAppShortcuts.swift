import AppIntents

struct EnoughAppShortcuts: AppShortcutsProvider {
  @AppShortcutsBuilder
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: StartReviewIntent(),
      phrases: [
        "Start my review in \(.applicationName)"
      ]
    )
  }
}
