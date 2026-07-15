import Foundation

enum ContentStoreError: Error {
  case missingResource(String)
  case deckNotFound(String)
  case countryNotFound(String)
}

final class ContentStore {
  private let bundle: Bundle
  private var cachedCatalog: ContentCatalog?
  private var cachedDecks: [String: [CardContent]] = [:]

  init(bundle: Bundle = .main) {
    self.bundle = bundle
  }

  func catalog() throws -> ContentCatalog {
    if let cached = cachedCatalog {
      return cached
    }

    guard
      let url = bundle.url(
        forResource: "catalog", withExtension: "json", subdirectory: "Content"
      )
    else {
      throw ContentStoreError.missingResource("Content/catalog.json")
    }

    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    let loaded = try decoder.decode(ContentCatalog.self, from: data)
    cachedCatalog = loaded
    return loaded
  }

  func cards(forDeck deckId: String) throws -> [CardContent] {
    if let cached = cachedDecks[deckId] {
      return cached
    }

    let catalog = try catalog()
    var deckFile: String?
    for country in catalog.countries {
      for deck in country.decks where deck.id == deckId {
        deckFile = deck.cardsFile
        break
      }
      if deckFile != nil { break }
    }

    guard let deckFile = deckFile else {
      throw ContentStoreError.deckNotFound(deckId)
    }

    let (filename, ext) = parsePath(deckFile)
    guard
      let url = bundle.url(
        forResource: filename, withExtension: ext, subdirectory: "Content/decks"
      )
    else {
      throw ContentStoreError.missingResource(deckFile)
    }

    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    let deckCards = try decoder.decode(DeckCards.self, from: data)
    cachedDecks[deckId] = deckCards.cards
    return deckCards.cards
  }

  func audioURL(forFile name: String) -> URL? {
    let (filename, ext) = parsePath(name)
    return bundle.url(forResource: filename, withExtension: ext, subdirectory: "Content/audio")
  }

  func country(_ id: String) throws -> CountryInfo {
    let catalog = try catalog()
    guard let found = catalog.countries.first(where: { $0.id == id }) else {
      throw ContentStoreError.countryNotFound(id)
    }
    return found
  }

  func deck(_ id: String) throws -> DeckInfo {
    let catalog = try catalog()
    for country in catalog.countries {
      for deck in country.decks where deck.id == id {
        return deck
      }
    }
    throw ContentStoreError.deckNotFound(id)
  }

  private func parsePath(_ path: String) -> (filename: String, extension: String) {
    let url = URL(fileURLWithPath: path)
    let filename = url.deletingPathExtension().lastPathComponent
    let ext = url.pathExtension
    return (filename, ext)
  }
}
