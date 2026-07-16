import XCTest

@testable import Enough

@MainActor
final class DebugRegistryTests: XCTestCase {
  func testAllIsNonEmpty() {
    XCTAssertFalse(DebugProviders.all.isEmpty)
  }

  func testSectionIdsAreUnique() {
    let ids = DebugProviders.all.map(\.id)
    XCTAssertEqual(ids.count, Set(ids).count)
  }

  func testAboutSectionExistsWithTwoRows() {
    let about = DebugProviders.all.first { $0.id == "about" }
    XCTAssertNotNil(about)
    XCTAssertEqual(about?.rows.count, 2)
  }

  func testRowIdsAreUniqueWithinEachSection() {
    for section in DebugProviders.all {
      let ids = section.rows.map(\.id)
      XCTAssertEqual(ids.count, Set(ids).count, "duplicate row ids in section \(section.id)")
    }
  }
}
