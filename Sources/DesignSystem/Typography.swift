import SwiftUI

enum EnoughFont {
  static func largeTitle() -> Font {
    .system(.largeTitle, weight: .bold)
  }

  static func screenTitle() -> Font {
    .system(.title, weight: .bold)
  }

  static func headline() -> Font {
    .system(.title2, weight: .semibold)
  }

  static func subEmphasis() -> Font {
    .system(.title3, weight: .semibold)
  }

  static func body() -> Font {
    .system(.body)
  }

  static func subhead() -> Font {
    .system(.subheadline)
  }

  static func footnote() -> Font {
    .system(.footnote)
  }

  static func eyebrow() -> Font {
    .system(.caption, weight: .semibold)
  }

  static func wordmark() -> Font {
    .system(size: 44, weight: .bold)
  }

  static let tightTracking: CGFloat = -0.02
  static let wordmarkTracking: CGFloat = -0.03
  static let eyebrowTracking: CGFloat = 0.06
}
