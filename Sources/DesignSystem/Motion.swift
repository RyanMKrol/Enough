import SwiftUI

enum Motion {
  static let bobDuration: Double = 4.0
  static let ringFill: Double = 1.2
  static let barGrow: Double = 1.0
  static let checkPop: Double = 0.5
  static let shake: Double = 0.5
  static let pulse: Double = 2.2
  static let flicker: Double = 2.2
  static let cardSwap: Double = 0.35
  static let popSpring: Animation = .spring(response: 0.5, dampingFraction: 0.55)
  static let swapSpring: Animation = .spring(response: 0.35, dampingFraction: 0.8)
}
