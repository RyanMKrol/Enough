import Foundation

@Observable
final class ProgressViewModel {
  private let services: AppServices

  var streak: Int = 0
  var dots: [DayDot] = []
  var wordsLearned: Int = 0
  var minutes: Int = 0
  var decksGoing: Int = 0
  var readinessPercent: Int = 0
  var readinessLine: String = ""
  var destination: String = ""

  init(services: AppServices) {
    self.services = services
  }

  func refresh() {
    streak = (try? services.stats.currentStreak()) ?? 0
    dots = (try? services.stats.weekDots()) ?? []
    wordsLearned = (try? services.deckProgress.wordsLearned()) ?? 0
    minutes = (try? services.stats.totalMinutes()) ?? 0

    guard let catalog = try? services.contentStore.catalog() else {
      decksGoing = 0
      readinessPercent = 0
      readinessLine = ""
      destination = ""
      return
    }

    let owned = (try? services.entitlementStore.ownedDeckIds(catalog: catalog)) ?? []
    decksGoing =
      owned.filter { deckId in
        ((try? services.deckProgress.progress(forDeck: deckId))?.learned ?? 0) > 0
      }.count

    guard let trip = try? services.tripStore.activeTrip(),
      let country = catalog.countries.first(where: { $0.id == trip.countryId })
    else {
      readinessPercent = 0
      readinessLine = ""
      destination = ""
      return
    }

    destination = Self.destinationLabel(countryId: trip.countryId, country: country)

    let tripScenarios = trip.scenarioIds.compactMap { scenarioId in
      catalog.scenarios.first(where: { $0.id == scenarioId })
    }

    let readiness = ReadinessCalculator.readiness(
      tripScenarios: tripScenarios,
      decks: country.decks,
      progress: { deckId in try? services.deckProgress.progress(forDeck: deckId) }
    )
    readinessPercent = readiness.percent
    readinessLine = readiness.line
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
