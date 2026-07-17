import Foundation

nonisolated enum ReadinessCalculator {
  static func readiness(
    tripScenarios: [ScenarioInfo],
    decks: [DeckInfo],
    progress: (String) -> DeckProgressService.DeckProgress?
  ) -> (percent: Int, line: String) {
    let tripIds = Set(tripScenarios.map(\.id))
    let participatingDecks = decks.filter { tripIds.contains($0.scenario) }

    let percent = overallPercent(decks: participatingDecks, progress: progress)
    let line = readinessLine(
      tripScenarios: tripScenarios, decks: participatingDecks, progress: progress)

    return (percent, line)
  }

  private static func overallPercent(
    decks: [DeckInfo],
    progress: (String) -> DeckProgressService.DeckProgress?
  ) -> Int {
    var totalCards = 0
    var totalLearned = 0
    for deck in decks {
      totalCards += deck.cardCount
      totalLearned += progress(deck.id)?.learned ?? 0
    }
    guard totalCards > 0 else { return 0 }
    let raw = (Double(totalLearned) / Double(totalCards) * 100).rounded()
    return min(100, max(0, Int(raw)))
  }

  private static func coverage(
    scenario: ScenarioInfo,
    decks: [DeckInfo],
    progress: (String) -> DeckProgressService.DeckProgress?
  ) -> Double {
    let scenarioDecks = decks.filter { $0.scenario == scenario.id }
    var totalCards = 0
    var totalLearned = 0
    for deck in scenarioDecks {
      totalCards += deck.cardCount
      totalLearned += progress(deck.id)?.learned ?? 0
    }
    guard totalCards > 0 else { return 0 }
    return Double(totalLearned) / Double(totalCards)
  }

  private static func noun(for scenario: ScenarioInfo) -> String {
    switch scenario.id {
    case "eating-out": return "food"
    case "greetings": return "greetings"
    case "getting-around": return "directions"
    case "nightlife": return "nightlife"
    case "shopping": return "shopping"
    case "emergencies": return "emergencies"
    default: return scenario.title.lowercased()
    }
  }

  private static func readinessLine(
    tripScenarios: [ScenarioInfo],
    decks: [DeckInfo],
    progress: (String) -> DeckProgressService.DeckProgress?
  ) -> String {
    let scenarioIds = Set(decks.map(\.scenario))
    let participating = tripScenarios.filter { scenarioIds.contains($0.id) }
    guard let firstScenario = participating.first else {
      return "Start with \(noun(for: tripScenarios.first ?? ScenarioInfo(id: "", title: "")))."
    }

    let coverages = participating.map {
      ($0, coverage(scenario: $0, decks: decks, progress: progress))
    }
    let handled = coverages.filter { $0.1 >= 0.6 }.map(\.0)
    let unhandled = coverages.filter { $0.1 < 0.6 }

    if handled.isEmpty {
      return "Start with \(noun(for: firstScenario))."
    }
    if unhandled.isEmpty {
      return "You're covered. Keep it fresh."
    }

    let nextScenario = lowestCoverageScenario(unhandled)
    let handledList = joinedNouns(handled.map(noun(for:)))
    return "You can handle \(handledList). \(capitalizedFirst(noun(for: nextScenario)))'s next."
  }

  private static func lowestCoverageScenario(
    _ unhandled: [(ScenarioInfo, Double)]
  ) -> ScenarioInfo {
    var best = unhandled[0]
    for entry in unhandled.dropFirst() where entry.1 < best.1 {
      best = entry
    }
    return best.0
  }

  private static func joinedNouns(_ nouns: [String]) -> String {
    switch nouns.count {
    case 0: return ""
    case 1: return nouns[0]
    case 2: return "\(nouns[0]) & \(nouns[1])"
    default:
      let head = nouns.dropLast().joined(separator: ", ")
      return "\(head) & \(nouns.last ?? "")"
    }
  }

  private static func capitalizedFirst(_ text: String) -> String {
    guard let first = text.first else { return text }
    return first.uppercased() + text.dropFirst()
  }
}
