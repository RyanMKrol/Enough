import Foundation

@Observable
final class PlanViewModel {
  private let country: CountryInfo
  private let draft: OnboardingDraft

  init(country: CountryInfo, draft: OnboardingDraft) {
    self.country = country
    self.draft = draft

    if draft.selectedBundleId == nil {
      seedBundle()
    }
  }

  private func seedBundle() {
    guard let allPacksBundle = country.bundles.max(by: { $0.deckIds.count < $1.deckIds.count })
    else {
      return
    }

    switch draft.duration {
    case .weekend:
      let weekendBundle = country.bundles.first { $0.popular }
      draft.selectedBundleId = weekendBundle?.id
    case .week:
      draft.selectedBundleId = allPacksBundle.id
    }
  }

  var selectedBundle: BundleInfo? {
    guard let selectedBundleId = draft.selectedBundleId else { return nil }
    return country.bundles.first { $0.id == selectedBundleId }
  }

  var packRows: [(deck: DeckInfo, state: PackRowState)] {
    let bundle = selectedBundle
    let bundleDeckIds = Set(bundle?.deckIds ?? [])

    let memberDecks = country.decks.filter { bundleDeckIds.contains($0.id) }
    let otherDecks = country.decks.filter { !bundleDeckIds.contains($0.id) }

    return (memberDecks + otherDecks).map { deck in
      (deck: deck, state: rowState(for: deck, bundle: bundle))
    }
  }

  private func rowState(for deck: DeckInfo, bundle: BundleInfo?) -> PackRowState {
    if let bundle, bundle.deckIds.contains(deck.id) {
      return .inBundle(bundleName: bundle.title)
    }
    let priceLabel = "+ " + PricingCalculator.price(deck.priceGBP)
    if draft.extraDeckIds.contains(deck.id) {
      return .extra(priceLabel: priceLabel)
    }
    return .available(priceLabel: priceLabel)
  }

  func bundleSubtitle(for bundle: BundleInfo) -> String {
    let savings = PricingCalculator.bundleSavings(bundle, in: country)
    return "\(bundle.subtitle) · save \(PricingCalculator.price(savings))"
  }

  func selectBundle(_ id: String) {
    draft.selectedBundleId = id
    guard let bundle = country.bundles.first(where: { $0.id == id }) else { return }
    let bundleDeckIds = Set(bundle.deckIds)
    draft.extraDeckIds.subtract(bundleDeckIds)
  }

  func togglePack(_ deckId: String) {
    if let bundle = selectedBundle, bundle.deckIds.contains(deckId) {
      return
    }
    if draft.extraDeckIds.contains(deckId) {
      draft.extraDeckIds.remove(deckId)
    } else {
      draft.extraDeckIds.insert(deckId)
    }
  }

  var total: Double {
    PricingCalculator.planTotal(
      selectedBundle: selectedBundle,
      extraDeckIds: draft.extraDeckIds,
      country: country
    )
  }

  var totalLabel: String {
    PricingCalculator.price(total)
  }

  var summary: String {
    PricingCalculator.summaryLine(selectedBundle: selectedBundle, extraDeckIds: draft.extraDeckIds)
  }

  var ctaTitle: String {
    if selectedBundle != nil {
      return "Get the bundle"
    }
    let count = draft.extraDeckIds.count
    return "Get \(count) pack\(count == 1 ? "" : "s")"
  }

  func purchaseSelection(purchase: PurchaseProviding) async throws -> PurchaseOutcome {
    var sawPending = false

    if let bundle = selectedBundle {
      let outcome = try await purchase.purchase(productId: bundle.id, kind: .bundle)
      switch outcome {
      case .cancelled:
        return .cancelled
      case .pending:
        sawPending = true
      case .success:
        break
      }
    }

    for deckId in draft.extraDeckIds {
      let outcome = try await purchase.purchase(productId: deckId, kind: .deck)
      switch outcome {
      case .cancelled:
        return .cancelled
      case .pending:
        sawPending = true
      case .success:
        break
      }
    }

    return sawPending ? .pending : .success
  }
}
