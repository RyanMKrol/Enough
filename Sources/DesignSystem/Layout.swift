import Foundation

enum Layout {
  static let buttonRadius: CGFloat = 16
  static let buttonHeight: CGFloat = 54
  static let chipRadius: CGFloat = 14
  static let cardRadius: CGFloat = 20
  static let heroRadius: CGFloat = 26
  static let flashcardRadius: CGFloat = 28
  static let screenHPad: CGFloat = 22
  static let cardPad: CGFloat = 18
  static let rowVPad: CGFloat = 12
  static let sectionGap: CGFloat = 18

  /// Vertical footprint of the floating `LiquidGlassTabBar`, measured up from the safe-area
  /// bottom edge, so bottom-pinned content (e.g. DeckDetail's action bar) can reserve room and
  /// not sit behind the glass. Derivation: bar body `minHeight 58` + `.padding(.vertical, 10)`
  /// (= 20) + MainShellView's `.padding(.bottom, 18)` = 96; plus a small breathing gap.
  static let floatingTabBarClearance: CGFloat = 96 + 12
}
