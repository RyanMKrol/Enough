import SwiftUI

struct CardStackHero: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var frontOffset: CGFloat = 0
  @State private var backLeftOffset: CGFloat = 0
  @State private var backRightOffset: CGFloat = 0
  @State private var isBobbing = false

  init() {
    // Empty init as specified
  }

  var body: some View {
    ZStack(alignment: .center) {
      // Back-left card (blue tint)
      RoundedRectangle(cornerRadius: 28)
        .fill(Color(hex: 0xe8f5ff))
        .frame(width: 165, height: 224)
        .rotationEffect(.degrees(-10))
        .offset(x: -36, y: 6 + backLeftOffset)

      // Back-right card (orange tint)
      RoundedRectangle(cornerRadius: 28)
        .fill(Color(hex: 0xfff0df))
        .frame(width: 165, height: 224)
        .rotationEffect(.degrees(10))
        .offset(x: 36, y: 6 + backRightOffset)

      // Front card (white with content)
      VStack(spacing: 0) {
        // Header band
        HStack(spacing: 8) {
          RoundedRectangle(cornerRadius: 9)
            .fill(.white)
            .frame(width: 30, height: 30)
            .overlay(
              Circle()
                .fill(Color(hex: 0xe24947))
                .frame(width: 13, height: 13)
            )

          Text("Japan")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color(hex: 0xa43b38))

          Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .background(Color(hex: 0xfff0ee))
        .border(
          Color(hex: 0xfedbd7),
          width: 1
        )

        // Stage below header
        VStack(spacing: 14) {
          Text("ありがとう")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(EnoughColor.label)

          Text("arigatō")
            .font(.system(size: 12.5, weight: .medium))
            .foregroundColor(Color(hex: 0xa45953))
            .tracking(12.5 * 0.04)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color(hex: 0xffe9e6))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)

        Spacer()
      }
      .frame(width: 165, height: 224)
      .background(.white)
      .cornerRadius(28)
      .overlay(
        RoundedRectangle(cornerRadius: 28)
          .stroke(Color.black.opacity(0.07), lineWidth: 1)
      )
      .shadow(
        color: Color.black.opacity(0.14),
        radius: 21,
        y: 20
      )
      .offset(y: frontOffset)
      .clipped()
    }
    .frame(width: 255, height: 292)
    .onAppear {
      if !reduceMotion {
        isBobbing = true
        startBobAnimation()
      }
    }
    .onDisappear {
      isBobbing = false
      frontOffset = 0
      backLeftOffset = 0
      backRightOffset = 0
    }
  }

  private func startBobAnimation() {
    guard isBobbing else { return }

    // Front card animation: ±6pt, 4s ease-in-out, infinite
    withAnimation(
      Animation.easeInOut(duration: Motion.bobDuration)
        .repeatForever(autoreverses: true)
    ) {
      frontOffset = 6
    }

    // Back-left card animation: ±4pt, 4s ease-in-out, phase offset 0.5s
    DispatchQueue.main.asyncAfter(deadline: .now() + Motion.bobPhaseOffsetShort) {
      guard isBobbing else { return }
      withAnimation(
        Animation.easeInOut(duration: Motion.bobDuration)
          .repeatForever(autoreverses: true)
      ) {
        backLeftOffset = 4
      }
    }

    // Back-right card animation: ±4pt, 4s ease-in-out, phase offset 1.0s
    DispatchQueue.main.asyncAfter(deadline: .now() + Motion.bobPhaseOffsetLong) {
      guard isBobbing else { return }
      withAnimation(
        Animation.easeInOut(duration: Motion.bobDuration)
          .repeatForever(autoreverses: true)
      ) {
        backRightOffset = 4
      }
    }
  }
}

#Preview {
  CardStackHero()
    .background(.white)
}
