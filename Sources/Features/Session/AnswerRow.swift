import SwiftUI

enum AnswerRowState: Equatable {
  case idle
  case correct
  case wrongShake
  case faded
  case correctOutline
}

struct AnswerRow: View {
  @Environment(\.accentTheme) var accentTheme

  let text: String
  let state: AnswerRowState
  let action: () -> Void

  @State private var shakeCounter: CGFloat = 0
  @State private var scale: CGFloat = 1

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Text(text)
          .font(.system(size: 17, weight: .medium))
          .lineLimit(2)
          .multilineTextAlignment(.leading)

        Spacer()

        trailingIcon
      }
      .frame(height: 56)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .padding(.horizontal, 16)
      .background(backgroundColor)
      .foregroundStyle(textColor)
      .clipShape(RoundedRectangle(cornerRadius: 15))
      .overlay(borderOverlay)
    }
    .allowsHitTesting(state == .idle)
    .scaleEffect(scale)
    .modifier(ShakeModifier(shakes: shakeCounter))
    .onChange(of: state) { oldState, newState in
      handleStateChange(from: oldState, to: newState)
    }
  }

  private var backgroundColor: Color {
    switch state {
    case .idle:
      return EnoughColor.insetSurface
    case .correct:
      return EnoughColor.successGreen
    case .wrongShake:
      return Color(hex: 0xffe9e6)
    case .faded:
      return EnoughColor.insetSurface
    case .correctOutline:
      return .white
    }
  }

  private var textColor: Color {
    switch state {
    case .idle:
      return EnoughColor.label
    case .correct:
      return .white
    case .wrongShake:
      return Color(hex: 0xb71824)
    case .faded:
      return Color(hex: 0xc0c0c6)
    case .correctOutline:
      return EnoughColor.label
    }
  }

  @ViewBuilder
  private var trailingIcon: some View {
    switch state {
    case .correct:
      CheckPopView(size: 22, color: .white)

    case .wrongShake:
      Image(systemName: "xmark.circle.fill")
        .font(.system(size: 22))
        .foregroundStyle(Color(hex: 0xb71824))

    case .correctOutline:
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 22))
        .foregroundStyle(EnoughColor.successGreen)

    case .idle, .faded:
      EmptyView()
    }
  }

  @ViewBuilder
  private var borderOverlay: some View {
    if state == .correctOutline {
      RoundedRectangle(cornerRadius: 15)
        .strokeBorder(EnoughColor.successGreen, lineWidth: 2)
    } else {
      EmptyView()
    }
  }

  private func handleStateChange(from oldState: AnswerRowState, to newState: AnswerRowState) {
    switch newState {
    case .correct:
      animateCorrect()
    case .wrongShake:
      animateWrongShake()
    default:
      break
    }
  }

  private func animateCorrect() {
    withAnimation(Motion.popSpring) {
      scale = 1.03
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + Motion.correctBounce) {
      withAnimation(Motion.popSpring) {
        scale = 1.0
      }
    }
  }

  private func animateWrongShake() {
    let newValue = shakeCounter + 1
    withAnimation(.linear(duration: Motion.shake)) {
      shakeCounter = newValue
    }
  }
}

private struct ShakeModifier: ViewModifier {
  let shakes: CGFloat

  func body(content: Content) -> some View {
    content
      .modifier(ShakeEffect(shakes: shakes))
  }
}

#Preview {
  ZStack {
    Color.white
      .ignoresSafeArea()

    VStack(spacing: 12) {
      AnswerRow(text: "Thank you very much", state: .idle) {}
      AnswerRow(text: "You're welcome", state: .correct) {}
      AnswerRow(text: "Excuse me", state: .wrongShake) {}
      AnswerRow(text: "Good morning", state: .faded) {}
      AnswerRow(text: "I'm sorry", state: .correctOutline) {}
    }
    .padding(20)
  }
}
