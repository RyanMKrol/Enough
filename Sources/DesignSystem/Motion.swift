import SwiftUI

enum Motion {
  // §1.4 motion vocabulary
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

  // Session-complete check pop sequencing
  static let completePop: Double = 0.55
  static let completePopDelay: Double = 0.3
  static let completePopDamping: Double = 0.55
  static let completePopSpring: Animation = .spring(
    response: completePop, dampingFraction: completePopDamping)

  // Tap-ripple decay on the audio button
  static let tapRippleDecay: Double = 0.8

  // Correct-answer micro bounce on an answer row
  static let correctBounce: Double = 0.25

  // General UI-polish micro-interactions (button press states, chip/card
  // selection, toast fades) — small, physical, purposeful per §1.4.
  static let pressFeedback: Double = 0.15
  static let pressFeedbackFast: Double = 0.1
  static let selectionFade: Double = 0.2
  static let selectionSpringResponse: Double = 0.3
  static let selectionSpringDamping: Double = 0.6
  static let cardFlip: Double = 0.4
  static let toastFade: Double = 0.35
  static let welcomeTransition: Double = 0.3

  // Card-stack bob phase offsets (back cards lag the front card)
  static let bobPhaseOffsetShort: Double = 0.5
  static let bobPhaseOffsetLong: Double = 1.0

  static let selectionSpring: Animation = .spring(
    response: selectionSpringResponse, dampingFraction: selectionSpringDamping)
}
