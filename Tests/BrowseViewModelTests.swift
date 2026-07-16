import XCTest

@testable import Enough

@MainActor
final class BrowseViewModelTests: XCTestCase {
  func testRefreshLoadsCatalogCountries() {
    let services = AppServices.preview()
    let vm = BrowseViewModel(services: services)
    vm.refresh()

    XCTAssertFalse(vm.countries.isEmpty)
  }

  func testCancelledOutcomeProducesNoStateChange() async {
    let purchase = FakePurchaseService()
    purchase.outcome = .cancelled
    let services = AppServices.preview()
    let vm = BrowseViewModel(services: services)

    await vm.buy(productId: "jp-greetings", kind: .deck, purchase: purchase)

    XCTAssertNil(vm.errorMessage)
    XCTAssertNil(vm.pendingProductId)
    XCTAssertNil(vm.inFlightProductId)
    XCTAssertFalse(purchase.ownedProductIds.contains("jp-greetings"))
  }

  func testPendingOutcomeShowsInlineNoteAndGrantsNothing() async {
    let purchase = FakePurchaseService()
    purchase.outcome = .pending
    let services = AppServices.preview()
    let vm = BrowseViewModel(services: services)

    await vm.buy(productId: "jp-greetings", kind: .deck, purchase: purchase)

    XCTAssertEqual(vm.pendingProductId, "jp-greetings")
    XCTAssertFalse(purchase.ownedProductIds.contains("jp-greetings"))
    XCTAssertNil(vm.errorMessage)
  }

  func testBuyingWhileInFlightIsBlocked() async {
    let purchase = FakePurchaseService()
    purchase.outcome = .success
    let services = AppServices.preview()
    let vm = BrowseViewModel(services: services)
    vm.inFlightProductId = "already-buying"

    await vm.buy(productId: "jp-greetings", kind: .deck, purchase: purchase)

    XCTAssertEqual(purchase.purchaseCallCount, 0)
  }

  func testRestoreShowsToastOnSuccess() async {
    let purchase = FakePurchaseService()
    let services = AppServices.preview()
    let vm = BrowseViewModel(services: services)

    await vm.restore(purchase: purchase)

    XCTAssertTrue(vm.showRestoredToast)
    XCTAssertNil(vm.errorMessage)
  }

  func testRestoreThrowingSetsErrorMessage() async {
    let purchase = FakePurchaseService()
    purchase.restoreShouldThrow = true
    let services = AppServices.preview()
    let vm = BrowseViewModel(services: services)

    await vm.restore(purchase: purchase)

    XCTAssertFalse(vm.showRestoredToast)
    XCTAssertNotNil(vm.errorMessage)
  }
}

private final class FakePurchaseService: PurchaseProviding {
  var outcome: PurchaseOutcome = .success
  var restoreShouldThrow = false
  private(set) var purchaseCallCount = 0
  private(set) var ownedProductIds: Set<String> = []

  func purchase(productId: String, kind: EntitlementKind) async throws -> PurchaseOutcome {
    purchaseCallCount += 1
    if outcome == .success {
      ownedProductIds.insert(productId)
    }
    return outcome
  }

  func restorePurchases() async throws {
    if restoreShouldThrow {
      struct RestoreError: Error {}
      throw RestoreError()
    }
  }

  func displayPrice(productId: String) -> String? { nil }
}
