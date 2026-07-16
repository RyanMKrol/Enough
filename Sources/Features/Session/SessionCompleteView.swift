import SwiftUI

struct SessionCompleteView: View {
  @Environment(\.services) private var services
  @Environment(\.accentTheme) var accentTheme

  let summary: SessionSummary
  let deckId: String?
  let onDone: () -> Void

  @State private var showCheck = false
  @State private var streak: Int = 0

  var body: some View {
    ZStack {
      Color.white.ignoresSafeArea()

      VStack(spacing: 0) {
        Spacer()

        heroSection

        Spacer()
          .frame(height: 18)

        titleSection

        Spacer()
          .frame(height: 18)

        sublineSection

        Spacer()
          .frame(height: 32)

        statTiles

        Spacer()

        actionsSection
          .padding(.horizontal, 20)
          .padding(.bottom, 22)
      }
    }
    .accessibilityIdentifier(AXID.screenSessionComplete)
    .task {
      streak = (try? services.stats.currentStreak()) ?? 0
      try? await Task.sleep(for: .seconds(0.3))
      withAnimation(Motion.popSpring) {
        showCheck = true
      }
    }
    .onAppear {
      Task {
        _ = await services.notifications.requestPermissionIfNeeded()
        await rescheduleReviewNotification()
      }
    }
  }

  private var heroSection: some View {
    ZStack {
      ProgressRing(
        progress: 1.0,
        size: 120,
        lineWidth: 8,
        tint: accentTheme.accent,
        showsPercent: false
      )

      if showCheck {
        CheckPopView(size: 44, color: accentTheme.accent)
      }
    }
  }

  private var titleSection: some View {
    Text("Round complete")
      .font(.system(size: 30, weight: .bold))
      .foregroundStyle(Color.black)
  }

  private var sublineSection: some View {
    let subline: String
    if summary.mode == .review {
      let strongestDeckTitle = getStrongestDeckTitle()
      subline = "You cleared today's reviews. \(strongestDeckTitle) is holding strong."
    } else {
      let deckTitle = getDeckTitle()
      subline = "That's \(deckTitle) under way. \(summary.cardsCompleted) cards down."
    }

    return Text(subline)
      .font(.system(size: 15, weight: .regular))
      .foregroundStyle(Color(hex: 0x6b6b70))
      .multilineTextAlignment(.center)
      .frame(maxWidth: 300)
  }

  private var statTiles: some View {
    HStack(spacing: 10) {
      statTile(
        value: String(summary.cardsCompleted),
        caption: "cards"
      )

      statTile(
        value: formatDuration(summary.duration),
        caption: "minutes"
      )

      statTile(
        value: String(streak),
        caption: "day streak"
      )
    }
    .padding(.horizontal, 20)
  }

  private func statTile(value: String, caption: String) -> some View {
    VStack(spacing: 8) {
      Text(value)
        .font(.system(size: 22, weight: .bold))
        .foregroundStyle(Color.black)

      Text(caption)
        .font(.system(size: 12, weight: .regular))
        .foregroundStyle(Color(hex: 0x8e8e93))
    }
    .frame(maxWidth: .infinity)
    .padding(14)
    .background(Color.white)
    .border(Color.black.opacity(0.08), width: 1)
    .cornerRadius(18)
  }

  private var actionsSection: some View {
    VStack(spacing: 12) {
      Button("Done") {
        onDone()
      }
      .buttonStyle(PrimaryButtonStyle(background: accentTheme.accent))

      if shouldShowLearnMore {
        Button("Learn 5 more") {
          handleLearnMore()
        }
        .buttonStyle(TextLinkButtonStyle())
      }
    }
  }

  private var shouldShowLearnMore: Bool {
    do {
      let engine = try services.study.makeLearnMoreSession(size: 5)
      return engine.current != nil
    } catch {
      return false
    }
  }

  private func handleLearnMore() {
    onDone()
  }

  private func getDeckTitle() -> String {
    guard let deckId else { return "the lesson" }
    do {
      let deck = try services.contentStore.deck(deckId)
      return deck.title
    } catch {
      return "the lesson"
    }
  }

  private func getStrongestDeckTitle() -> String {
    do {
      let catalog = try services.contentStore.catalog()
      let owned = try services.entitlementStore.ownedDeckIds(catalog: catalog)

      var strongestDeckId: String?
      var strongestDeckTitle: String?
      var strongestStrength: Int = -1
      var strongestLearned: Int = -1

      for deckId in owned {
        let progress = try services.deckProgress.progress(forDeck: deckId)
        let isStronger = progress.strength > strongestStrength
        let isSameLearned =
          progress.strength == strongestStrength && progress.mastered > strongestLearned
        if strongestDeckId == nil || isStronger || isSameLearned {
          let deck = try services.contentStore.deck(deckId)
          strongestDeckId = deckId
          strongestDeckTitle = deck.title
          strongestStrength = progress.strength
          strongestLearned = progress.mastered
        }
      }

      return strongestDeckTitle ?? "your strongest deck"
    } catch {
      return "your strongest deck"
    }
  }

  private func rescheduleReviewNotification() async {
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

  private func formatDuration(_ seconds: TimeInterval) -> String {
    let totalSeconds = Int(seconds.rounded())
    let minutes = totalSeconds / 60
    let secs = totalSeconds % 60
    return String(format: "%d:%02d", minutes, secs)
  }
}

#Preview {
  Group {
    SessionCompleteView(
      summary: SessionSummary(
        cardsCompleted: 12,
        correctCount: 10,
        duration: 250,
        mode: .review
      ),
      deckId: nil,
      onDone: {}
    )
    .environment(\.accentTheme, .japan)
    .environment(\.services, .preview())

    SessionCompleteView(
      summary: SessionSummary(
        cardsCompleted: 5,
        correctCount: 4,
        duration: 125,
        mode: .learn
      ),
      deckId: "jp-basic",
      onDone: {}
    )
    .environment(\.accentTheme, .japan)
    .environment(\.services, .preview())
  }
}
