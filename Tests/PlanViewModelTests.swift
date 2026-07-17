import XCTest

@testable import Enough

@MainActor
final class PlanViewModelTests: XCTestCase {
  var store: ContentStore!
  var japan: CountryInfo!

  override func setUp() async throws {
    try await super.setUp()
    store = ContentStore()
    japan = try XCTUnwrap(try store.country("japan"))
  }

  func testWeekendDraftSeedsWeekendBundle() {
    let draft = OnboardingDraft()
    draft.duration = .weekend
    let vm = PlanViewModel(country: japan, draft: draft)
    _ = vm
    XCTAssertEqual(draft.selectedBundleId, "jp-weekend")
  }

  func testWeekDraftSeedsWholeWeekBundle() {
    let draft = OnboardingDraft()
    draft.duration = .week
    let vm = PlanViewModel(country: japan, draft: draft)
    _ = vm
    XCTAssertEqual(draft.selectedBundleId, "jp-week")
  }

  func testSeedingRespectsAlreadySetBundle() {
    let draft = OnboardingDraft()
    draft.duration = .weekend
    draft.selectedBundleId = "jp-week"
    _ = PlanViewModel(country: japan, draft: draft)
    XCTAssertEqual(draft.selectedBundleId, "jp-week")
  }

  func testPackRowsAndToggle() {
    let draft = OnboardingDraft()
    draft.duration = .weekend
    let vm = PlanViewModel(country: japan, draft: draft)

    let rows = vm.packRows
    let getGetting = rows.first { $0.deck.id == "jp-getting-around" }
    guard let gettingRow = getGetting else {
      XCTFail("expected jp-getting-around row")
      return
    }
    guard case .available(let label) = gettingRow.state else {
      XCTFail("expected available state, got \(gettingRow.state)")
      return
    }
    XCTAssertEqual(label, "+ £1.00")

    for id in ["jp-greetings", "jp-ordering-food", "jp-at-the-bar"] {
      let row = rows.first { $0.deck.id == id }
      guard case .inBundle(let bundleName) = row?.state else {
        XCTFail("expected inBundle state for \(id)")
        return
      }
      XCTAssertEqual(bundleName, "Weekend")
    }

    vm.togglePack("jp-getting-around")
    let toggledRows = vm.packRows
    let toggledRow = toggledRows.first { $0.deck.id == "jp-getting-around" }
    guard case .extra = toggledRow?.state else {
      XCTFail("expected extra state after toggle")
      return
    }
    XCTAssertEqual(vm.total, 3.49, accuracy: 0.001)
    XCTAssertEqual(vm.totalLabel, "£3.49")
  }

  func testTogglePackOnBundleMemberIsNoOp() {
    let draft = OnboardingDraft()
    draft.duration = .weekend
    let vm = PlanViewModel(country: japan, draft: draft)

    vm.togglePack("jp-greetings")
    XCTAssertFalse(draft.extraDeckIds.contains("jp-greetings"))
  }

  func testSummaryAndCTA() {
    let draft = OnboardingDraft()
    draft.duration = .weekend
    let vm = PlanViewModel(country: japan, draft: draft)

    XCTAssertEqual(vm.summary, "Weekend · 3 packs")
    XCTAssertEqual(vm.ctaTitle, "Get the bundle")
  }

  func testPurchaseSelectionSuccessGrantsAllProducts() async throws {
    let draft = OnboardingDraft()
    draft.duration = .weekend
    let vm = PlanViewModel(country: japan, draft: draft)
    vm.togglePack("jp-getting-around")

    let purchaseStub = InMemoryPurchaseService()
    let outcome = try await vm.purchaseSelection(purchase: purchaseStub)

    XCTAssertEqual(outcome, .success)
    XCTAssertTrue(purchaseStub.ownedProductIds.contains("jp-weekend"))
    XCTAssertTrue(purchaseStub.ownedProductIds.contains("jp-getting-around"))
  }
}

private final class InMemoryPurchaseService: PurchaseProviding {
  private(set) var ownedProductIds: Set<String> = []

  func purchase(productId: String, kind: EntitlementKind) async throws -> PurchaseOutcome {
    ownedProductIds.insert(productId)
    return .success
  }

  func restorePurchases() async throws {}

  func displayPrice(productId: String) -> String? { nil }
}
