import SwiftUI

extension Color {
  init(hex: UInt32) {
    let red = Double((hex >> 16) & 0xFF) / 255.0
    let green = Double((hex >> 8) & 0xFF) / 255.0
    let blue = Double(hex & 0xFF) / 255.0
    self.init(red: red, green: green, blue: blue)
  }
}

enum EnoughColor {
  static let canvas = Color(hex: 0xf2f2f7)
  static let surface = Color(hex: 0xffffff)
  static let insetSurface = Color(hex: 0xf7f7fa)
  static let label = Color(hex: 0x1c1c1e)
  static let secondaryText = Color(hex: 0x6b6b70)
  static let tertiaryText = Color(hex: 0x8e8e93)
  static let faintText = Color(hex: 0xa0a0a6)
  static let inactiveTab = Color(hex: 0xb0b0b6)
  static let hairline = Color.black.opacity(0.08)
  static let graphite = Color(hex: 0x1c1c1e)
  static let linkBlue = Color(hex: 0x3d7ede)
  static let successGreen = Color(hex: 0x1c8742)
  static let successTint = Color(hex: 0xd8f9dd)
  static let successDeep = Color(hex: 0x00722e)
  static let easyBlue = Color(hex: 0x1666aa)
  static let easyTint = Color(hex: 0xcaf7ff)
  static let streakAmber = Color(hex: 0xde6907)
  static let streakAmberTint = Color(hex: 0xffecdd)
}
