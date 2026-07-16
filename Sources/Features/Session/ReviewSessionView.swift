import SwiftUI

struct ReviewSessionView: View {
  @Environment(\.services) private var services
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: ReviewSessionViewModel?
  @State private var path: [SessionRoute] = []

  let engine: SessionEngine

  init(engine: SessionEngine) {
    self.engine = engine
  }

  var body: some View {
    NavigationStack(path: $path) {
      content
        .navigationDestination(for: SessionRoute.self) { route in
          switch route {
          case .complete:
            SessionCompleteView(
              summary: engine.summary(),
              deckId: nil,
              onDone: { dismiss() }
            )
          }
        }
    }
  }

  @ViewBuilder
  private var content: some View {
    if let viewModel {
      ZStack {
        EnoughColor.canvas.ignoresSafeArea()

        VStack(spacing: 0) {
          SessionChrome(
            progress: viewModel.progressValue,
            counterText: viewModel.progressText,
            onClose: {
              viewModel.closeAndCommit()
              dismiss()
            }
          )
          .padding(.horizontal, 20)
          .padding(.top, 12)

          Spacer()

          if let cardContent = cardContent(viewModel: viewModel) {
            FlashcardView(
              card: cardContent,
              isRevealed: Binding(
                get: { viewModel.isRevealed },
                set: { viewModel.isRevealed = $0 }
              ),
              onPlayAudio: { viewModel.replayAudio() }
            )
            .padding(.horizontal, 20)
            .id(viewModel.currentCardId)
            .transition(
              .asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .leading))
            )
            .animation(Motion.swapSpring, value: viewModel.currentCardId)
          }

          Spacer()

          if viewModel.isRevealed {
            VStack(spacing: 14) {
              Text("How well did you know it?")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color(hex: 0x8e8e93))
                .multilineTextAlignment(.center)

              GradeButtonRow(previews: viewModel.previews, onGrade: viewModel.grade)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
          }
        }
      }
      .accessibilityIdentifier(AXID.screenSessionReview)
      .onChange(of: viewModel.route) { _, newRoute in
        if let newRoute {
          path.append(newRoute)
        }
      }
    } else {
      EnoughColor.canvas.ignoresSafeArea()
        .onAppear {
          viewModel = ReviewSessionViewModel(engine: engine, services: services)
        }
    }
  }

  private func cardContent(viewModel: ReviewSessionViewModel) -> CardContent? {
    guard let card = engine.current else { return nil }
    return try? services.contentStore.cards(forDeck: card.deckId)
      .first(where: { $0.id == card.cardId })
  }
}

#Preview {
  ReviewSessionView(engine: SessionEngine(mode: .review, cards: [], now: { Date() }))
    .environment(\.accentTheme, .japan)
    .environment(\.services, .preview())
}
