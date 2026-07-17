import SwiftUI

struct StreakCard: View {
  let streak: Int
  let dots: [DayDot]

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.isTabActive) private var isTabActive

  @State private var isAnimating = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        Image(systemName: "flame.fill")
          .font(.system(size: 26))
          .foregroundColor(EnoughColor.streakAmber)
          .scaleEffect(isAnimating ? 1.08 : 1.0)
          .rotationEffect(.degrees(isAnimating ? 3 : -3))
          .accessibilityHidden(true)

        Text("\(streak)-day streak")
          .font(.system(size: 22, weight: .bold))
          .foregroundColor(EnoughColor.label)

        Spacer()
      }

      Text("Keep it alive — 3 min today does it")
        .font(.system(size: 13, weight: .regular))
        .foregroundColor(Color(hex: 0x6b6b70))

      WeekDotsRow(dots: dots)
    }
    .padding(18)
    .background(
      LinearGradient(
        gradient: Gradient(
          colors: [
            EnoughColor.streakAmberTint,
            Color.white,  // swiftlint:disable:this trailing_comma
          ]
        ),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .cornerRadius(20)
    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    .onAppear { updateFlicker() }
    .onChange(of: isTabActive) { _, _ in updateFlicker() }
  }

  private func updateFlicker() {
    guard isTabActive, !reduceMotion else {
      isAnimating = false
      return
    }
    withAnimation(
      .easeInOut(duration: Motion.flicker)
        .repeatForever(autoreverses: true)
    ) {
      isAnimating = true
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    StreakCard(
      streak: 6,
      dots: [DayDot.done, .done, .done, .done, .done, .today, .upcoming]
    )
    .padding()
  }
  .padding()
  .background(EnoughColor.canvas)
}
