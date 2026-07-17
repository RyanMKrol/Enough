import SwiftUI

struct OnboardingBackButton: View {
  @Environment(\.dismiss) var dismiss

  var body: some View {
    Button(
      action: { dismiss() },
      label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(EnoughColor.label)
          .frame(width: 34, height: 34)
          .background(EnoughColor.canvas)
          .clipShape(Circle())
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
    )
    .accessibilityLabel("Back")
  }
}
