import SwiftUI

struct TapRipple: Identifiable {
  let id = UUID()
  var scale: CGFloat
  var opacity: Double
}

struct PulsingAudioButton: View {
  @Environment(\.accentTheme) var accentTheme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let size: CGFloat
  let isPulsing: Bool
  let action: () -> Void

  @State private var pulseScale: CGFloat = 0.85
  @State private var pulseOpacity: Double = 0.6
  @State private var tapRipples: [TapRipple] = []
  @State private var isVisible = false

  init(size: CGFloat = 60, isPulsing: Bool = true, action: @escaping () -> Void) {
    self.size = size
    self.isPulsing = isPulsing
    self.action = action
  }

  var body: some View {
    Button(action: onTap) {
      ZStack {
        // Tap ripple rings
        ForEach(Array(tapRipples.enumerated()), id: \.element.id) { _, ripple in
          Circle()
            .stroke(accentTheme.accent, lineWidth: 2)
            .scaleEffect(ripple.scale)
            .opacity(ripple.opacity)
        }

        // Idle pulse ring (behind fill, when pulsing enabled)
        if isPulsing {
          Circle()
            .stroke(accentTheme.accent, lineWidth: 2)
            .scaleEffect(pulseScale)
            .opacity(pulseOpacity)
        }

        // Circle fill
        Circle()
          .fill(accentTheme.tint)

        // Speaker icon
        Image(systemName: "speaker.wave.2.fill")
          .font(.system(size: size * 0.4, weight: .semibold))
          .foregroundStyle(accentTheme.accent)
      }
      .frame(width: size, height: size)
      .onAppear {
        if isPulsing && !reduceMotion {
          isVisible = true
          startIdlePulse()
        }
      }
      .onDisappear {
        isVisible = false
        pulseScale = 0.85
        pulseOpacity = 0.6
      }
    }
    .accessibilityIdentifier(AXID.audioButton)
  }

  private func onTap() {
    action()
    addTapRipple()
  }

  private func startIdlePulse() {
    guard isVisible else { return }
    withAnimation(
      .easeOut(duration: Motion.pulse).repeatForever(autoreverses: false)
    ) {
      pulseScale = 1.7
      pulseOpacity = 0.0
    }
  }

  private func addTapRipple() {
    let ripple = TapRipple(scale: 0.85, opacity: 0.6)
    tapRipples.append(ripple)

    withAnimation(.easeOut(duration: Motion.tapRippleDecay)) {
      if let index = tapRipples.firstIndex(where: { $0.id == ripple.id }) {
        tapRipples[index].scale = 1.7
        tapRipples[index].opacity = 0.0
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + Motion.tapRippleDecay) {
      tapRipples.removeAll { $0.id == ripple.id }
    }
  }
}

#Preview {
  HStack(spacing: 20) {
    PulsingAudioButton(size: 60, isPulsing: true) {
      print("Pulsing audio button tapped")
    }

    PulsingAudioButton(size: 34, isPulsing: false) {
      print("Non-pulsing audio button tapped")
    }
  }
  .padding(20)
}
