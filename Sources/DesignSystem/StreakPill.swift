import SwiftUI

struct StreakPill: View {
  let count: Int

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.isTabActive) private var isTabActive

  @State private var isAnimating = false

  var body: some View {
    HStack(spacing: 5) {
      Image(systemName: "flame.fill")
        .font(.system(size: 15))
        .foregroundColor(EnoughColor.streakAmber)
        .scaleEffect(isAnimating ? 1.08 : 1.0)
        .rotationEffect(.degrees(isAnimating ? 3 : -3))

      Text("\(count)")
        .font(.system(size: 15, weight: .bold))
        .foregroundColor(EnoughColor.label)
    }
    .padding(.vertical, 7)
    .padding(.horizontal, 12)
    .background(EnoughColor.surface)
    .clipShape(Capsule())
    .shadow(
      color: Color.black.opacity(0.05),
      radius: 3,
      x: 0,
      y: 1
    )
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
  StreakPill(count: 6)
    .padding()
    .background(EnoughColor.canvas)
}
