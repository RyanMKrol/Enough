import SwiftUI

struct CheckPopView: View {
  let size: CGFloat
  let color: Color

  @State private var isAnimating = false

  var body: some View {
    ZStack {
      Circle()
        .fill(color)
        .frame(width: size, height: size)

      Image(systemName: "checkmark")
        .font(.system(size: size * 0.5, weight: .bold))
        .foregroundColor(.white)
    }
    .scaleEffect(isAnimating ? 1 : 0)
    .onAppear {
      withAnimation(Motion.popSpring) {
        isAnimating = true
      }
    }
  }
}

struct ShakeEffect: GeometryEffect {
  var shakes: CGFloat

  var animatableData: CGFloat {
    get { shakes }
    set { shakes = newValue }
  }

  func effectValue(size: CGSize) -> ProjectionTransform {
    let translation = 8 * sin(shakes * .pi * 6)
    return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
  }
}

struct BottomResultSheet<Content: View>: View {
  let tint: Color
  let onContinue: (() -> Void)?
  let content: Content

  init(
    tint: Color,
    onContinue: (() -> Void)? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.tint = tint
    self.onContinue = onContinue
    self.content = content()
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      VStack(spacing: 0) {
        Spacer()

        HStack(spacing: 16) {
          content

          Spacer()

          if onContinue != nil {
            Button(action: onContinue ?? {}) {
              Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.15))
                .clipShape(Circle())
            }
            .accessibilityLabel("Continue")
          }
        }
        .padding(20)
        .padding(.bottom, 16)
      }
      .frame(maxWidth: .infinity, alignment: .topLeading)
      .background(tint)
      .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
    }
    .transition(.move(edge: .bottom))
  }
}

#Preview {
  ZStack(alignment: .bottom) {
    Color(hex: 0xf2f2f7)
      .ignoresSafeArea()

    VStack(spacing: 40) {
      VStack(alignment: .leading, spacing: 12) {
        Text("Check Pop")
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(.gray)
          .textCase(.uppercase)

        HStack {
          CheckPopView(size: 56, color: Color(hex: 0x1c8742))
          Spacer()
        }
      }

      VStack(alignment: .leading, spacing: 12) {
        Text("Shake Effect")
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(.gray)
          .textCase(.uppercase)

        ZStack {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.white)

          Text("Shakes on answer")
            .font(.system(size: 14))
            .foregroundColor(.gray)
        }
        .frame(height: 60)
      }

      Spacer()
    }
    .padding(20)

    BottomResultSheet(
      tint: Color(hex: 0xd8f9dd),
      onContinue: {},
      content: {
        VStack(alignment: .leading, spacing: 4) {
          Text("Nice.")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(Color(hex: 0x1c1c1e))

          Text("You'll see this again in 2 days")
            .font(.system(size: 15))
            .foregroundColor(Color(hex: 0x6b6b70))
        }
      })
  }
}
