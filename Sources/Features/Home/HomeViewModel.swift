import Foundation

struct HomeDeckRow: Identifiable {
  let deck: DeckInfo
  let progress: Double
  let status: DeckRowStatus

  var id: String { deck.id }
}

@Observable
final class HomeViewModel {
  private let services: AppServices

  var subtitle: String = ""
  var streak: Int = 0
  var continueDeck: (deck: DeckInfo, progress: DeckProgressService.DeckProgress)?
  var continueDetailLine: String = ""
  var dueCount: Int = 0
  var deckRows: [HomeDeckRow] = []

  init(services: AppServices) {
    self.services = services
  }

  func reload() {
    guard let catalog = try? services.contentStore.catalog() else { return }
    guard let trip = try? services.tripStore.activeTrip() else { return }

    let country = catalog.countries.first(where: { $0.id == trip.countryId })
    let destinationLabel = Self.destinationLabel(countryId: trip.countryId, country: country)
    let durationLabel = Self.durationLabel(for: trip.duration)
    let dayNumber = (try? services.tripStore.dayNumber(now: services.dateProvider.now)) ?? 1

    subtitle = "\(durationLabel) in \(destinationLabel) · Day \(dayNumber)"
    streak = (try? services.stats.currentStreak()) ?? 0
    dueCount = (try? services.deckProgress.totalDue()) ?? 0

    let ownedIds = (try? services.entitlementStore.ownedDeckIds(catalog: catalog)) ?? []
    let ownedDecks: [DeckInfo] = country?.decks.filter { ownedIds.contains($0.id) } ?? []
    let progresses: [(deck: DeckInfo, progress: DeckProgressService.DeckProgress)] =
      ownedDecks.compactMap { deck in
        guard let progress = try? services.deckProgress.progress(forDeck: deck.id) else {
          return nil
        }
        return (deck: deck, progress: progress)
      }

    if let inProgress = progresses.first(where: {
      $0.progress.learned > 0 && $0.progress.learned < $0.progress.total
    }) {
      continueDeck = inProgress
    } else if let untouched = progresses.first(where: { $0.progress.learned == 0 }) {
      continueDeck = untouched
    } else {
      continueDeck = nil
    }

    if let continueDeck {
      let remaining = continueDeck.progress.total - continueDeck.progress.learned
      let minutes = max(1, Int((Double(remaining) * 25.0 / 60.0).rounded()))
      continueDetailLine =
        "\(continueDeck.progress.learned) of \(continueDeck.progress.total) cards · about \(minutes) min left"
    } else {
      continueDetailLine = ""
    }

    deckRows = progresses.map { entry in
      let status: DeckRowStatus
      if entry.progress.learned == entry.progress.total {
        status = .learned
      } else if entry.progress.learned == 0 {
        status = .new
      } else {
        status = .progress(entry.progress.learned, entry.progress.total)
      }
      let progressFraction =
        entry.progress.total > 0
        ? Double(entry.progress.learned) / Double(entry.progress.total) : 0
      return HomeDeckRow(deck: entry.deck, progress: progressFraction, status: status)
    }
  }

  private static func durationLabel(for duration: String) -> String {
    switch duration {
    case "weekend": return "Weekend"
    case "week": return "A week"
    default: return duration.capitalized
    }
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
