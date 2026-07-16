import Foundation
import XCTest

final class PrivacyManifestTests: XCTestCase {
  func testPrivacyManifestIsBundled() {
    let bundle = Bundle.main
    let url = bundle.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
    XCTAssertNotNil(url, "PrivacyInfo.xcprivacy should exist in app bundle")
  }

  func testPrivacyManifestIsValidPlist() throws {
    guard
      let url = Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
    else {
      XCTFail("PrivacyInfo.xcprivacy not found")
      return
    }

    let data = try Data(contentsOf: url)
    let plist = try PropertyListSerialization.propertyList(
      from: data, options: [], format: nil)
    XCTAssertTrue(
      plist is [String: Any], "PrivacyInfo.xcprivacy should be a valid plist dictionary")
  }

  func testPrivacyManifestHasCorrectStructure() throws {
    guard
      let url = Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
    else {
      XCTFail("PrivacyInfo.xcprivacy not found")
      return
    }

    let data = try Data(contentsOf: url)
    guard
      let plist = try PropertyListSerialization.propertyList(
        from: data, options: [], format: nil) as? [String: Any]
    else {
      XCTFail("PrivacyInfo.xcprivacy is not a valid plist dictionary")
      return
    }

    XCTAssertEqual(plist["NSPrivacyTracking"] as? NSNumber, 0, "NSPrivacyTracking should be false")
    XCTAssertTrue(
      plist["NSPrivacyTrackingDomains"] is [Any],
      "NSPrivacyTrackingDomains should be empty array")
    XCTAssertTrue(
      plist["NSPrivacyCollectedDataTypes"] is [Any],
      "NSPrivacyCollectedDataTypes should be empty array")
    XCTAssertTrue(
      plist["NSPrivacyAccessedAPITypes"] is [Any],
      "NSPrivacyAccessedAPITypes should be an array")

    if let apiTypes = plist["NSPrivacyAccessedAPITypes"] as? [[String: Any]] {
      XCTAssertFalse(
        apiTypes.isEmpty, "NSPrivacyAccessedAPITypes should contain at least one entry")

      let userDefaultsEntry = apiTypes.first {
        $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults"
      }
      XCTAssertNotNil(
        userDefaultsEntry,
        "NSPrivacyAccessedAPITypes should contain UserDefaults category")

      guard let entry = userDefaultsEntry else { return }
      let reasons = entry["NSPrivacyAccessedAPITypeReasons"] as? [String]
      XCTAssertNotNil(reasons, "UserDefaults entry should have reasons")
      if let reasons = reasons {
        XCTAssertTrue(
          reasons.contains("CA92.1"), "UserDefaults should have CA92.1 reason code")
      }
    }
  }
}
