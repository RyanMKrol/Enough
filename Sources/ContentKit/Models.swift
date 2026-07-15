nonisolated struct ContentCatalog: Codable {
  let version: Int
  let scenarios: [ScenarioInfo]
  let countries: [CountryInfo]
  let comingSoon: [String]
}

nonisolated struct ScenarioInfo: Codable, Identifiable, Equatable {
  let id: String
  let title: String
}

nonisolated struct CountryInfo: Codable, Identifiable, Equatable {
  let id: String
  let name: String
  let languageName: String
  let nativeLanguageName: String
  let accent: String
  let flagEmoji: String
  let decks: [DeckInfo]
  let bundles: [BundleInfo]
}

nonisolated struct DeckInfo: Codable, Identifiable, Equatable {
  let id: String
  let title: String
  let subtitle: String
  let scenario: String
  let icon: String
  let cardsFile: String
  let cardCount: Int
  let priceGBP: Double
}

nonisolated struct BundleInfo: Codable, Identifiable, Equatable {
  let id: String
  let title: String
  let subtitle: String
  let deckIds: [String]
  let priceGBP: Double
  let popular: Bool
}

nonisolated struct DeckCards: Codable {
  let deckId: String
  let cards: [CardContent]
}

nonisolated struct CardContent: Codable, Identifiable, Equatable {
  let id: String
  let english: String
  let target: String
  let pronunciation: String
  let audio: String
  let notes: String?
  let category: String?
}
