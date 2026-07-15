import SwiftUI
import XCTest

@testable import Enough

@MainActor
final class DesignTokensTests: XCTestCase {
  private let colorAccuracy: CGFloat = 0.01

  func testEnoughColorHexValues() {
    assertColorEqual(EnoughColor.linkBlue, hex: 0x3d7ede, name: "linkBlue")
    assertColorEqual(EnoughColor.successGreen, hex: 0x1c8742, name: "successGreen")
    assertColorEqual(EnoughColor.canvas, hex: 0xf2f2f7, name: "canvas")
    assertColorEqual(EnoughColor.label, hex: 0x1c1c1e, name: "label")
    assertColorEqual(EnoughColor.streakAmber, hex: 0xde6907, name: "streakAmber")
  }

  func testAccentThemeColors() {
    assertColorEqual(AccentTheme.japan.accent, hex: 0xe24947, name: "japan.accent")
    assertColorEqual(AccentTheme.france.accent, hex: 0x3d7ede, name: "france.accent")
    assertColorEqual(AccentTheme.germany.accent, hex: 0xd07b00, name: "germany.accent")
    assertColorEqual(AccentTheme.japan.tint, hex: 0xffe9e6, name: "japan.tint")
  }

  func testAccentThemeRawValues() {
    XCTAssertEqual(AccentTheme(rawValue: "japan"), .japan)
    XCTAssertEqual(AccentTheme(rawValue: "france"), .france)
    XCTAssertEqual(AccentTheme(rawValue: "germany"), .germany)
    XCTAssertNil(AccentTheme(rawValue: "spain"))
  }

  func testLayoutConstants() {
    XCTAssertEqual(Layout.buttonHeight, 54)
    XCTAssertEqual(Layout.buttonRadius, 16)
  }

  func testMotionConstants() {
    XCTAssertEqual(Motion.bobDuration, 4.0)
    XCTAssertEqual(Motion.cardSwap, 0.35)
  }

  func testEnoughFontSemanticStyles() {
    XCTAssertEqual(EnoughFont.body(), Font.system(.body))
    XCTAssertEqual(EnoughFont.largeTitle(), Font.system(.largeTitle, weight: .bold))
  }

  func testDefaultAccentTheme() {
    let env = EnvironmentValues()
    XCTAssertEqual(env.accentTheme, .japan)
  }

  // MARK: - Helpers

  private func assertColorEqual(
    _ color: Color,
    hex: UInt32,
    name: String,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let uiColor = UIColor(color)
    let expectedColor = UIColor(hex: hex)

    var expectedR: CGFloat = 0
    var expectedG: CGFloat = 0
    var expectedB: CGFloat = 0
    var expectedA: CGFloat = 0
    var actualR: CGFloat = 0
    var actualG: CGFloat = 0
    var actualB: CGFloat = 0
    var actualA: CGFloat = 0

    expectedColor.getRed(&expectedR, green: &expectedG, blue: &expectedB, alpha: &expectedA)
    uiColor.getRed(&actualR, green: &actualG, blue: &actualB, alpha: &actualA)

    let tolerance = colorAccuracy
    XCTAssertEqual(
      actualR,
      expectedR,
      accuracy: tolerance,
      "\(name) red mismatch",
      file: file,
      line: line
    )
    XCTAssertEqual(
      actualG,
      expectedG,
      accuracy: tolerance,
      "\(name) green mismatch",
      file: file,
      line: line
    )
    XCTAssertEqual(
      actualB,
      expectedB,
      accuracy: tolerance,
      "\(name) blue mismatch",
      file: file,
      line: line
    )
  }
}

extension UIColor {
  convenience init(hex: UInt32) {
    let red = CGFloat((hex >> 16) & 0xFF) / 255.0
    let green = CGFloat((hex >> 8) & 0xFF) / 255.0
    let blue = CGFloat(hex & 0xFF) / 255.0
    self.init(red: red, green: green, blue: blue, alpha: 1.0)
  }
}
