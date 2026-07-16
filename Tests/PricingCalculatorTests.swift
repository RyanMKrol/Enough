import XCTest

@testable import Enough

@MainActor
final class PricingCalculatorTests: XCTestCase {
  var japan: CountryInfo!

  override func setUp() async throws {
    try await super.setUp()
    let store = ContentStore()
    let catalog = try store.catalog()
    japan = try XCTUnwrap(catalog.countries.first { $0.id == "japan" })
  }

  func testPrice() {
    XCTAssertEqual(PricingCalculator.price(2.49), "£2.49")
    XCTAssertEqual(PricingCalculator.price(1), "£1.00")
    XCTAssertEqual(PricingCalculator.price(8.99), "£8.99")
  }

  func testBundleSavings() throws {
    let weekendBundle = try XCTUnwrap(japan.bundles.first { $0.id == "jp-weekend" })
    let weekBundle = try XCTUnwrap(japan.bundles.first { $0.id == "jp-week" })

    let weekendSavings = PricingCalculator.bundleSavings(weekendBundle, in: japan)
    XCTAssertEqual(weekendSavings, 0.51)

    let weekSavings = PricingCalculator.bundleSavings(weekBundle, in: japan)
    XCTAssertEqual(weekSavings, 0.51)
  }

  func testPlanTotalWithBundleAndExtra() throws {
    let weekendBundle = try XCTUnwrap(japan.bundles.first { $0.id == "jp-weekend" })

    let total = PricingCalculator.planTotal(
      selectedBundle: weekendBundle,
      extraDeckIds: ["jp-getting-around"],
      country: japan
    )
    XCTAssertEqual(total, 3.49)
  }

  func testPlanTotalWithBundleAndExtraDeckAlreadyInBundle() throws {
    let weekendBundle = try XCTUnwrap(japan.bundles.first { $0.id == "jp-weekend" })

    let total = PricingCalculator.planTotal(
      selectedBundle: weekendBundle,
      extraDeckIds: ["jp-greetings"],
      country: japan
    )
    XCTAssertEqual(total, 2.49)
  }

  func testPlanTotalWithoutBundle() {
    let total = PricingCalculator.planTotal(
      selectedBundle: nil,
      extraDeckIds: ["jp-greetings", "jp-at-the-bar"],
      country: japan
    )
    XCTAssertEqual(total, 2.0)
  }

  func testPlanTotalWithoutBundleOrExtras() {
    let total = PricingCalculator.planTotal(
      selectedBundle: nil,
      extraDeckIds: [],
      country: japan
    )
    XCTAssertEqual(total, 0)
  }

  func testSummaryLineWithBundleAndNoExtras() throws {
    let weekendBundle = try XCTUnwrap(japan.bundles.first { $0.id == "jp-weekend" })

    let summary = PricingCalculator.summaryLine(selectedBundle: weekendBundle, extraDeckIds: [])
    XCTAssertEqual(summary, "Weekend · 3 packs")
  }

  func testSummaryLineWithBundleAndOneExtra() throws {
    let weekendBundle = try XCTUnwrap(japan.bundles.first { $0.id == "jp-weekend" })

    let summary = PricingCalculator.summaryLine(
      selectedBundle: weekendBundle,
      extraDeckIds: ["jp-getting-around"]
    )
    XCTAssertEqual(summary, "Weekend · 4 packs")
  }

  func testSummaryLineWithoutBundleAndOneExtra() {
    let summary = PricingCalculator.summaryLine(selectedBundle: nil, extraDeckIds: ["jp-greetings"])
    XCTAssertEqual(summary, "1 pack")
  }

  func testSummaryLineWithoutBundleOrExtras() {
    let summary = PricingCalculator.summaryLine(selectedBundle: nil, extraDeckIds: [])
    XCTAssertEqual(summary, "No packs")
  }
}
