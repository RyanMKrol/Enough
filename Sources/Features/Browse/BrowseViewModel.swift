import Foundation

@Observable
final class BrowseViewModel {
  private let services: AppServices
  // SAFE: deinit is nonisolated by language rule and NSObjectProtocol observer tokens are
  // documented as safe to remove from any thread, so this is the standard teardown escape valve.
  private nonisolated(unsafe) var entitlementsToken: NSObjectProtocol?

  var countries: [CountryInfo] = []
  var comingSoon: [String] = []
  var ownedDeckIds: Set<String> = []
  var ownedProductIds: Set<String> = []
  var inFlightProductId: String?
  var errorMessage: String?
  var pendingProductId: String?
  var showRestoredToast: Bool = false

  init(services: AppServices) {
    self.services = services
    entitlementsToken = NotificationCenter.default.addObserver(
      forName: .entitlementsChanged, object: nil, queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.refresh()
      }
    }
  }

  deinit {
    if let entitlementsToken {
      NotificationCenter.default.removeObserver(entitlementsToken)
    }
  }

  func refresh() {
    guard let catalog = try? services.contentStore.catalog() else { return }

    let activeTrip = try? services.tripStore.activeTrip()
    let activeCountryId = activeTrip.flatMap { $0 }?.countryId
    let activeIndex = activeCountryId.flatMap { id in
      catalog.countries.firstIndex(where: { $0.id == id })
    }
    if let activeIndex {
      var ordered = catalog.countries
      let active = ordered.remove(at: activeIndex)
      countries = [active] + ordered
    } else {
      countries = catalog.countries
    }

    comingSoon = catalog.comingSoon
    ownedDeckIds = (try? services.entitlementStore.ownedDeckIds(catalog: catalog)) ?? []
    ownedProductIds = services.purchase.ownedProductIds
  }

  func buy(productId: String, kind: EntitlementKind, purchase: PurchaseProviding? = nil) async {
    guard inFlightProductId == nil else { return }
    inFlightProductId = productId
    let purchase = purchase ?? services.purchase

    do {
      let outcome = try await purchase.purchase(productId: productId, kind: kind)
      switch outcome {
      case .success:
        refresh()
      case .cancelled:
        break
      case .pending:
        pendingProductId = productId
      }
    } catch {
      errorMessage = error.localizedDescription
    }

    inFlightProductId = nil
  }

  func restore(purchase: PurchaseProviding? = nil) async {
    let purchase = purchase ?? services.purchase
    do {
      try await purchase.restorePurchases()
      showRestoredToast = true
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func price(for productId: String, fallbackGBP: Double) -> String {
    services.purchase.displayPrice(productId: productId) ?? PricingCalculator.price(fallbackGBP)
  }
}
