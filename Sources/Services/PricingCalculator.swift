import Foundation

enum PricingCalculator {
  private static let currencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "en_GB")
    return formatter
  }()

  static func price(_ gbp: Double) -> String {
    currencyFormatter.string(from: NSNumber(value: gbp)) ?? "£0.00"
  }

  static func bundleSavings(_ bundle: BundleInfo, in country: CountryInfo) -> Double {
    let individualTotal = bundle.deckIds.reduce(0.0) { total, deckId in
      if let deck = country.decks.first(where: { $0.id == deckId }) {
        return total + deck.priceGBP
      }
      return total
    }
    let savings = individualTotal - bundle.priceGBP
    return (savings * 100).rounded() / 100
  }

  static func planTotal(
    selectedBundle: BundleInfo?,
    extraDeckIds: Set<String>,
    country: CountryInfo
  ) -> Double {
    let bundlePrice = selectedBundle?.priceGBP ?? 0
    let bundleDeckIds = Set(selectedBundle?.deckIds ?? [])

    let extraPrice = extraDeckIds.reduce(0.0) { total, deckId in
      guard !bundleDeckIds.contains(deckId),
        let deck = country.decks.first(where: { $0.id == deckId })
      else {
        return total
      }
      return total + deck.priceGBP
    }

    let total = bundlePrice + extraPrice
    return (total * 100).rounded() / 100
  }

  static func summaryLine(selectedBundle: BundleInfo?, extraDeckIds: Set<String>) -> String {
    let bundleCount = selectedBundle?.deckIds.count ?? 0
    let extraCount = extraDeckIds.count
    let totalCount = bundleCount + extraCount

    if totalCount == 0 {
      return "No packs"
    }

    let packWord = totalCount == 1 ? "pack" : "packs"

    if let bundle = selectedBundle {
      return "\(bundle.title) · \(totalCount) \(packWord)"
    } else {
      return "\(totalCount) \(packWord)"
    }
  }
}
