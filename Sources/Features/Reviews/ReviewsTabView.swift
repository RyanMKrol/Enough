import SwiftUI

struct ReviewsTabView: View {
  @Environment(\.services) var services
  @Environment(\.accentTheme) var accentTheme

  @State private var reviewSessionEngine: SessionEngine?
  @State private var isShowingReviewSession = false
  // swiftlint:disable:next large_tuple
  @State private var dueCounts: (due: Int, learning: Int, mastered: Int) = (0, 0, 0)
  @State private var deckProgresses: [String: DeckProgressService.DeckProgress] = [:]
  @State private var ownedDeckIds: [String] = []
  @State private var destinationLabel: String = ""
  @State private var nextDueDate: Date?

  var dueCount: Int { dueCounts.due }
  var learningCount: Int { dueCounts.learning }
  // swiftlint:disable:next inclusive_language
  var masteredCount: Int { dueCounts.mastered }

  var ringProgress: Double {
    let total = dueCount + learningCount
    guard total > 0 else { return 1.0 }
    return Double(dueCount) / Double(total)
  }

  var minutesNeeded: Int {
    max(1, Int(ceil(Double(dueCount) * 20.0 / 60.0)))
  }

  var body: some View {
    ZStack {
      EnoughColor.canvas.ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: Layout.sectionGap) {
          VStack(alignment: .leading, spacing: 4) {
            Text("Reviews")
              .font(EnoughFont.largeTitle())
              .foregroundStyle(EnoughColor.label)

            Text("Keeping \(destinationLabel) fresh")
              .font(.system(size: 15, weight: .regular))
              .foregroundStyle(EnoughColor.secondaryText)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, Layout.screenHPad)
          .padding(.top, 12)

          if dueCount > 0 {
            heroCardWithDue()
          } else {
            heroCardEmpty()
          }

          statTiles()
          deckStrengthList()
        }
        .padding(.horizontal, Layout.screenHPad)
        .padding(.bottom, 32)
      }
    }
    .accessibilityIdentifier(AXID.screenReviews)
    .onAppear {
      reload()
    }
    .fullScreenCover(isPresented: $isShowingReviewSession) {
      if let reviewSessionEngine {
        ReviewSessionView(engine: reviewSessionEngine)
      }
    }
  }

  @ViewBuilder
  private func heroCardWithDue() -> some View {
    VStack(spacing: 20) {
      HStack(spacing: 0) {
        ProgressRing(
          progress: ringProgress,
          size: 120,
          lineWidth: 6,
          tint: accentTheme.accent,
          showsPercent: false
        )

        VStack(spacing: 0) {
          Text(String(dueCount))
            .font(.system(size: 30, weight: .bold))
            .foregroundStyle(EnoughColor.label)

          Text("due now")
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(EnoughColor.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .center)
      }
      .frame(height: 160, alignment: .center)

      VStack(spacing: 14) {
        Text("A quick \(minutesNeeded)-minute round keeps these from slipping.")
          .font(.system(size: 15, weight: .regular))
          .foregroundStyle(EnoughColor.secondaryText)
          .lineLimit(3)

        Button(action: startReviewSession) {
          Text("Start review")
        }
        .buttonStyle(PrimaryButtonStyle(background: accentTheme.accent))
        .accessibilityIdentifier(AXID.startReview)
      }
    }
    .padding(Layout.cardPad)
    .background(EnoughColor.surface)
    .cornerRadius(Layout.cardRadius)
    .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
  }

  @ViewBuilder
  private func heroCardEmpty() -> some View {
    VStack(spacing: 14) {
      Text("Nothing due right now")
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(EnoughColor.label)

      if let nextDueDate {
        Text("Next review \(nextDueDate, style: .relative)")
          .font(.system(size: 13, weight: .regular))
          .foregroundStyle(EnoughColor.secondaryText)
      }

      Button(action: startReviewSession) {
        Text("Start review")
      }
      .buttonStyle(PrimaryButtonStyle(background: accentTheme.accent))
      .accessibilityIdentifier(AXID.startReview)
      .opacity(0.5)
      .disabled(true)
    }
    .padding(Layout.cardPad)
    .background(EnoughColor.surface)
    .cornerRadius(Layout.cardRadius)
    .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
  }

  @ViewBuilder
  private func statTiles() -> some View {
    HStack(spacing: 12) {
      statTile(label: "Due", count: dueCount, color: Color(hex: 0xb71824))
      statTile(label: "Learning", count: learningCount, color: EnoughColor.streakAmber)
      statTile(label: "Mastered", count: masteredCount, color: EnoughColor.successGreen)
    }
  }

  @ViewBuilder
  private func statTile(label: String, count: Int, color: Color) -> some View {
    VStack(spacing: 8) {
      Text(String(count))
        .font(.system(size: 22, weight: .bold))
        .foregroundStyle(color)

      Text(label)
        .font(.system(size: 12, weight: .semibold))
        .tracking(0.05)
        .textCase(.uppercase)
        .foregroundStyle(EnoughColor.label)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(EnoughColor.surface)
    .cornerRadius(18)
  }

  @ViewBuilder
  private func deckStrengthList() -> some View {
    VStack(spacing: 0) {
      ForEach(Array(ownedDeckIds.enumerated()), id: \.element) { index, deckId in
        if let progress = deckProgresses[deckId] {
          deckStrengthRow(deckId: deckId, progress: progress)

          if index < ownedDeckIds.count - 1 {
            Divider()
              .padding(.leading, 54)
          }
        }
      }
    }
    .background(EnoughColor.surface)
    .cornerRadius(18)
  }

  @ViewBuilder
  private func deckStrengthRow(
    deckId: String,
    progress: DeckProgressService.DeckProgress
  ) -> some View {
    HStack(spacing: 12) {
      StrengthBars(strength: progress.strength)

      if let deck = getDeckInfo(deckId) {
        Text(deck.title)
          .font(.system(size: 17, weight: .regular))
          .foregroundStyle(EnoughColor.label)
      }

      Spacer()

      Text("\(progress.dueNow) due")
        .font(.system(size: 13, weight: .regular))
        .foregroundStyle(EnoughColor.tertiaryText)
    }
    .padding(.horizontal, Layout.cardPad)
    .padding(.vertical, Layout.rowVPad)
  }

  private func getDeckInfo(_ deckId: String) -> DeckInfo? {
    guard let catalog = try? services.contentStore.catalog() else { return nil }
    for country in catalog.countries {
      if let deck = country.decks.first(where: { $0.id == deckId }) {
        return deck
      }
    }
    return nil
  }

  private func startReviewSession() {
    guard let engine = try? services.study.makeReviewSession() else { return }
    reviewSessionEngine = engine
    isShowingReviewSession = true
  }

  private func reload() {
    guard let catalog = try? services.contentStore.catalog() else { return }
    guard let trip = try? services.tripStore.activeTrip() else { return }

    let country = catalog.countries.first(where: { $0.id == trip.countryId })
    destinationLabel = Self.destinationLabel(countryId: trip.countryId, country: country)

    if let totals = try? services.deckProgress.totals() {
      dueCounts = totals
    }

    let owned = (try? services.entitlementStore.ownedDeckIds(catalog: catalog)) ?? []
    ownedDeckIds = Array(owned)

    var progresses: [String: DeckProgressService.DeckProgress] = [:]
    for deckId in owned {
      if let progress = try? services.deckProgress.progress(forDeck: deckId) {
        progresses[deckId] = progress
      }
    }
    deckProgresses = progresses

    if dueCount == 0 {
      nextDueDate = getNextDueDate()
    }
  }

  private func getNextDueDate() -> Date? {
    guard let catalog = try? services.contentStore.catalog() else { return nil }
    let owned = (try? services.entitlementStore.ownedDeckIds(catalog: catalog)) ?? []
    let now = services.dateProvider.now

    var earliestDueDate: Date?

    for deckId in owned {
      guard let records = try? services.cardSRSStore.records(forDeck: deckId) else { continue }
      for record in records {
        if let dueAt = record.dueAt, dueAt > now {
          if let earliest = earliestDueDate {
            if dueAt < earliest {
              earliestDueDate = dueAt
            }
          } else {
            earliestDueDate = dueAt
          }
        }
      }
    }

    return earliestDueDate
  }

  private static func destinationLabel(countryId: String, country: CountryInfo?) -> String {
    switch countryId {
    case "japan": return "Tokyo"
    case "france": return "Paris"
    case "germany": return "Berlin"
    default: return country?.name ?? countryId
    }
  }
}

#Preview {
  ReviewsTabView()
    .environment(\.accentTheme, .japan)
    .environment(\.services, AppServices.preview())
}
