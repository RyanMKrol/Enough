import SwiftUI

struct FlashcardView: View {
  @Environment(\.accentTheme) var accentTheme

  let card: CardContent
  @Binding var isRevealed: Bool
  let onPlayAudio: () -> Void

  @State private var flipAngle: Double = 0

  var body: some View {
    VStack(spacing: 14) {
      ZStack {
        RoundedRectangle(cornerRadius: 28)
          .fill(EnoughColor.surface)
          .shadow(color: .black.opacity(0.14), radius: 21, x: 0, y: 20)

        ZStack {
          frontFace
            .opacity(flipAngle < 90 ? 1 : 0)

          backFace
            .rotation3DEffect(
              .degrees(180),
              axis: (x: 0, y: 1, z: 0)
            )
            .opacity(flipAngle >= 90 ? 1 : 0)
        }
        .rotation3DEffect(
          .degrees(flipAngle),
          axis: (x: 0, y: 1, z: 0)
        )
      }
      .frame(maxWidth: .infinity)
      .frame(minHeight: 380)
      .padding(22)
      .onTapGesture {
        if !isRevealed {
          withAnimation(.easeInOut(duration: 0.4)) {
            flipAngle = 180
            isRevealed = true
          }
        }
      }
      .onChange(of: isRevealed) { _, newValue in
        if !newValue {
          withAnimation(nil) {
            flipAngle = 0
          }
        }
      }

      if !isRevealed {
        Text("Tap the card to reveal")
          .font(.system(size: 13, weight: .regular))
          .foregroundStyle(EnoughColor.tertiaryText)
          .padding(.top, 14)
      }
    }
  }

  private var frontFace: some View {
    VStack(spacing: 18) {
      PulsingAudioButton(size: 60, isPulsing: true, action: onPlayAudio)

      Text(card.target)
        .font(.system(size: 36, weight: .bold))
        .foregroundStyle(EnoughColor.label)
        .multilineTextAlignment(.center)
    }
  }

  private var backFace: some View {
    VStack(spacing: 0) {
      VStack(spacing: 4) {
        Text(card.target)
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(accentTheme.deep)
          .multilineTextAlignment(.center)

        Text(card.pronunciation)
          .font(.system(size: 13, weight: .regular))
          .foregroundStyle(accentTheme.deep)
          .multilineTextAlignment(.center)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .padding(.horizontal, 18)
      .background(accentTheme.tint)

      VStack(spacing: 14) {
        Text(card.english)
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(EnoughColor.label)
          .multilineTextAlignment(.center)

        PulsingAudioButton(size: 34, isPulsing: false, action: onPlayAudio)
      }
      .frame(maxWidth: .infinity)
      .frame(maxHeight: .infinity)
    }
  }
}

#Preview("Front") {
  let previewCard = CardContent(
    id: "preview",
    english: "Thank you very much",
    target: "ありがとうございます",
    pronunciation: "arigatō gozaimasu",
    audio: "preview.mp3",
    notes: nil,
    category: nil
  )

  ZStack {
    EnoughColor.canvas
      .ignoresSafeArea()

    VStack {
      FlashcardView(
        card: previewCard,
        isRevealed: .constant(false),
        onPlayAudio: { print("Audio tapped") }
      )
      .padding(28)

      Spacer()
    }
  }
  .environment(\.accentTheme, .japan)
}

#Preview("Revealed") {
  let previewCard = CardContent(
    id: "preview",
    english: "Thank you very much",
    target: "ありがとうございます",
    pronunciation: "arigatō gozaimasu",
    audio: "preview.mp3",
    notes: nil,
    category: nil
  )

  ZStack {
    EnoughColor.canvas
      .ignoresSafeArea()

    VStack {
      FlashcardView(
        card: previewCard,
        isRevealed: .constant(true),
        onPlayAudio: { print("Audio tapped") }
      )
      .padding(28)

      Spacer()
    }
  }
  .environment(\.accentTheme, .japan)
}
